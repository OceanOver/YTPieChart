//
//  YTPieChart.m
//  YTPieChart
//
//  Created by MacbookPro on 16/5/7.
//  Copyright © 2016年 OceanOver. All rights reserved.
//

#import "YTPieChart.h"
#import <QuartzCore/QuartzCore.h>

/**
 *  slice layer of chart
 */
@interface ChartSlice : CAShapeLayer

@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) double startAngle;
@property (nonatomic, assign) double endAngle;

@end

@implementation ChartSlice

@end

#pragma mark -

@interface YTPieChart () {
    //first slice start angle
    double _startPieAngle;
    NSInteger _selelctedIndex;
    CGFloat _pieRadius;
    CGPoint _pieCenter;
}

@end

@implementation YTPieChart

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self baseConfigWithFrame:frame];
    }
    return self;
}

#pragma mark - support xib
- (id)initWithCoder:(NSCoder *)aDecoder {
    if ([super initWithCoder:aDecoder]) {
        CGRect frame = self.frame;
        [self baseConfigWithFrame:frame];
    }
    return self;
}

- (void)baseConfigWithFrame:(CGRect)frame {
    CGFloat width = MIN(frame.size.width, frame.size.height);
    CGFloat x = frame.origin.x;
    CGFloat y = frame.origin.y;
    frame = CGRectMake(x, y, width, width);
    self.frame = frame;
    self.backgroundColor = [UIColor clearColor];
    self.allowsSelection = YES;
    _startPieAngle = 0.0;
    _selelctedIndex = -1; // select none
    self.selectSliceLineWidth = 2.0;
    _pieRadius = frame.size.width / 2;
    _pieCenter = CGPointMake(frame.size.width / 2, frame.size.height / 2);
    self.titleFont = [UIFont boldSystemFontOfSize:MAX((int)_pieRadius / 10, 5)];
}

#pragma mark - create slice layer (with textLayer)
- (ChartSlice *)createSliceLayerWithTitle:(NSString *)title {
    ChartSlice *sliceLayer = [ChartSlice layer];
    sliceLayer.strokeColor = NULL;
    if (!title) {
        return sliceLayer;
    }
    CATextLayer *textLayer = [CATextLayer layer];
    CGFontRef font = CGFontCreateWithFontName((__bridge CFStringRef)[self.titleFont fontName]);
    textLayer.font = font;
    CFRelease(font);
    textLayer.string = title;
    textLayer.fontSize = self.titleFont.pointSize;
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.backgroundColor = [UIColor clearColor].CGColor;
    textLayer.foregroundColor = self.titleColor.CGColor;
    CGSize size = [title sizeWithAttributes:@{NSFontAttributeName : self.titleFont}];
    [CATransaction setDisableActions:YES];
    textLayer.bounds = CGRectMake(0, 0, size.width, size.height);
    textLayer.position = CGPointMake(_pieCenter.x, _pieCenter.y);
    [CATransaction setDisableActions:NO];
    [sliceLayer addSublayer:textLayer];
    return sliceLayer;
}

#pragma mark - create slice path
- (CGPathRef)createPathWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, center.x, center.y);

    CGPathAddArc(path, NULL, center.x, center.y, radius, startAngle, endAngle, 0);
    CGPathCloseSubpath(path);

    return path;
}

#pragma mark - touch interaction
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.allowsSelection) {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];

    NSArray *sliceLayers = self.layer.sublayers;
    [sliceLayers enumerateObjectsUsingBlock:^(ChartSlice *sliceLayer, NSUInteger index, BOOL *_Nonnull stop) {
        CGPathRef path = sliceLayer.path;
        if (CGPathContainsPoint(path, nil, point, false)) {
            if (!sliceLayer.isSelected) {
                [self deselectSliceAtIndex:_selelctedIndex];
                [self selectSliceAtIndex:index];
            }
            else {
                [self deselectSliceAtIndex:index];
            }
        }
    }];
}

#pragma mark - method
- (void)reloadData {
    if (_dataSource) {
        self.userInteractionEnabled = NO;

        CALayer *parentLayer = self.layer;
        NSArray *sliceLayers = parentLayer.sublayers;
        [sliceLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];

        //values
        double sum = 0;
        NSInteger sliceCount = 0;
        if ([_dataSource respondsToSelector:@selector(numberOfSlicesInChart:)]) {
            sliceCount = [_dataSource numberOfSlicesInChart:self];
        }
        double values[sliceCount];
        for (int i = 0; i < sliceCount; i++) {
            double value = 0.0;
            if ([_dataSource respondsToSelector:@selector(chart:valueForSliceAtIndex:)]) {
                value = [_dataSource chart:self valueForSliceAtIndex:i];
            }
            sum += value;
            values[i] = value;
        }

        //angles
        double angles[sliceCount];
        for (int i = 0; i < sliceCount; i++) {
            double angle = 0.0;
            if (sum != 0) {
                double value = values[i];
                angle = value / sum * 2 * M_PI;
            }
            angles[i] = angle;
        }

        //sliceLayers
        double startToAngle = 0.0;
        double endToAngle = startToAngle;
        NSMutableArray *mutableLayers = [NSMutableArray arrayWithArray:sliceLayers];
        for (int index = 0; index < sliceCount; index++) {
            NSString *title = nil;
            if ([_dataSource respondsToSelector:@selector(chart:titleForSliceAtIndex:)]) {
                title = [_dataSource chart:self titleForSliceAtIndex:index];
            }
            ChartSlice *layer = [self createSliceLayerWithTitle:title];
            layer.isSelected = NO;
            double angle = angles[index];
            endToAngle += angle;
            double startFromAngle = _startPieAngle + startToAngle;
            double endFromAngle = _startPieAngle + endToAngle;

            CGPathRef path = [self createPathWithCenter:_pieCenter radius:_pieRadius startAngle:startFromAngle endAngle:endFromAngle];
            layer.path = path;
            CFRelease(path);
            layer.startAngle = startFromAngle;
            layer.endAngle = endFromAngle;
            [parentLayer addSublayer:layer];

            UIColor *color = nil;
            if ([_dataSource respondsToSelector:@selector(chart:colorForSliceAtIndex:)]) {
                color = [_dataSource chart:self colorForSliceAtIndex:index];
            }
            if (!color) {
                color = [UIColor colorWithHue:((index / 8) % 20) / 20.0 + 0.02 saturation:(index % 8 + 3) / 10.0 brightness:91 / 100.0 alpha:1];
            }
            layer.fillColor = color.CGColor;

            startToAngle = endToAngle;
        }

        [mutableLayers removeAllObjects];

        self.userInteractionEnabled = YES;
        
        [self updateTextLayer];
    }
}

- (void)updateTextLayer {
    CALayer *parentLayer = self.layer;
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(ChartSlice * sliceLayer, NSUInteger index, BOOL *stop) {
        
        double startAngle = sliceLayer.startAngle;
        double endAngle = sliceLayer.endAngle;
        
        CALayer *labelLayer = [[sliceLayer sublayers] objectAtIndex:0];
        double midAngle = (startAngle + endAngle) / 2;
        [CATransaction setDisableActions:YES];
        CGFloat labelRadius = 0.6 * _pieRadius;
        [labelLayer setPosition:CGPointMake(_pieCenter.x + (labelRadius * cos(midAngle)), _pieCenter.y + (labelRadius * sin(midAngle)))];
        [CATransaction setDisableActions:NO];
    }];
}

- (void)selectSliceAtIndex:(NSInteger)index {
    ChartSlice *sliceLayer = (ChartSlice *) self.layer.sublayers[index];
    sliceLayer.lineWidth = self.selectSliceLineWidth;
    sliceLayer.strokeColor = [UIColor whiteColor].CGColor;
    sliceLayer.lineJoin = kCALineJoinBevel;
    sliceLayer.zPosition = MAXFLOAT;
    _selelctedIndex = index;
    sliceLayer.isSelected = YES;
    if ([_delegate respondsToSelector:@selector(chart:didSelectSliceAtIndex:)]) {
        [_delegate chart:self didSelectSliceAtIndex:index];
    }
}

- (void)deselectSliceAtIndex:(NSInteger)index {
    if (_selelctedIndex < 0) {
        return;
    }
    ChartSlice *sliceLayer = (ChartSlice *) self.layer.sublayers[index];
    sliceLayer.strokeColor = NULL;
    sliceLayer.lineWidth = 0;
    _selelctedIndex = -1;
     sliceLayer.zPosition = 100;
    sliceLayer.isSelected = NO;
    if ([_delegate respondsToSelector:@selector(chart:didDeselectSliceAtIndex:)]) {
        [_delegate chart:self didDeselectSliceAtIndex:index];
    }
}

@end

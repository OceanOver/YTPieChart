//
//  YTPieChart.h
//  YTPieChart
//
//  Created by MacbookPro on 16/5/7.
//  Copyright © 2016年 OceanOver. All rights reserved.
//

#import <UIKit/UIKit.h>
@class YTPieChart;

/**
 *  this protocol represents the data model object.
 */
@protocol YTPieChartDataSource <NSObject>

@required
- (NSInteger)numberOfSlicesInChart:(YTPieChart *)chart;
- (CGFloat)chart:(YTPieChart *)chart valueForSliceAtIndex:(NSInteger)index;
- (UIColor *)chart:(YTPieChart *)chart colorForSliceAtIndex:(NSInteger)index;

@optional
- (NSString *)chart:(YTPieChart *)chart titleForSliceAtIndex:(NSInteger)index;

@end

/**
 *  this represents the behaviour of the slices.
 */
@protocol YTPieChartDelegate <NSObject>

@optional
- (void)chart:(YTPieChart *)chart didSelectSliceAtIndex:(NSInteger)index;
- (void)chart:(YTPieChart *)chart didDeselectSliceAtIndex:(NSInteger)index;

@end

/**
 *  YTPieChart
 */
@interface YTPieChart : UIView

@property (nonatomic, weak) id<YTPieChartDataSource> dataSource;
@property (nonatomic, weak) id<YTPieChartDelegate> delegate;
@property (nonatomic, assign) BOOL allowsSelection;
@property (nonatomic, assign) CGFloat selectSliceLineWidth;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *titleColor;

- (void)reloadData;
- (void)selectSliceAtIndex:(NSInteger)index;
- (void)deselectSliceAtIndex:(NSInteger)index;

@end

//
//  JTListView.h
//  JTListView
//
//  Created by Jun on 5/6/11.
//  Copyright 2011 Jun Tanaka. All rights reserved.
//

#import <Foundation/Foundation.h>


@class JTListView;


typedef enum {
    JTListViewLayoutLeftToRight,
    JTListViewLayoutRightToLeft,
    JTListViewLayoutTopToBottom,
    JTListViewLayoutBottomToTop
} JTListViewLayout;


typedef enum {
    JTListViewScrollPositionNone   = UITableViewScrollPositionNone,
    JTListViewScrollPositionCenter = UITableViewRowAnimationMiddle,
    JTListViewScrollPositionCenterElseNone // center if the view size is smaller than bounds size, else none
} JTListViewScrollPosition;


@protocol JTListViewDataSource <NSObject>
@required
- (NSUInteger)numberOfItemsInListView:(JTListView *)listView;
- (UIView *)listView:(JTListView *)listView viewForItemAtIndex:(NSUInteger)index;

@end


@protocol JTListViewDelegate <UIScrollViewDelegate>
@optional
- (void)listView:(JTListView *)listView willDisplayView:(UIView *)view forItemAtIndex:(NSUInteger)index;

- (CGFloat)listView:(JTListView *)listView widthForItemAtIndex:(NSUInteger)index;  // for horizontal layouts
- (CGFloat)listView:(JTListView *)listView heightForItemAtIndex:(NSUInteger)index; // for vertical layouts

@end


@interface JTListView : UIScrollView {
@package
    NSMutableArray *_itemRects;
    NSRange         _visibleRange;
    NSMutableArray *_visibleViews;
    NSMutableSet   *_reuseableViews;
}

@property (nonatomic, assign) IBOutlet id <JTListViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id <JTListViewDelegate>   delegate;

@property (nonatomic) JTListViewLayout layout;
@property (nonatomic) CGFloat          itemWidth;       // for horizontal layouts. default is 44.0
@property (nonatomic) CGFloat          itemHeight;      // for vertical layouts. default is 44.0
@property (nonatomic) CGFloat          gapBetweenItems; // default is zero
@property (nonatomic) UIEdgeInsets     visibleInsets;   // set negative values to load views outside bounds. default is UIEdgeInsetsZero

- (id)initWithFrame:(CGRect)frame layout:(JTListViewLayout)layout; // must specify style at creation. -initWithFrame: calls this with JTListViewLayoutLeftToRight

- (void)reloadData;
- (void)reloadItemsAtIndexes:(NSIndexSet *)indexes;

- (void)updateItemSizes;
- (void)updateItemSizesAtIndexes:(NSIndexSet *)indexes;

- (NSUInteger)numberOfItems;

- (CGRect)rectForItemAtIndex:(NSUInteger)index;         // returns CGRectNull if index is out of range
- (UIView *)viewForItemAtIndex:(NSUInteger)index;       // returns nil if view is not visible or index is out of range

- (NSUInteger)indexForView:(UIView *)view;              // returns NSNotFound if view is not visible
- (NSUInteger)indexForItemAtPoint:(CGPoint)point;       // returns NSNotFound if point is outside list
- (NSUInteger)indexForItemAtCenterOfBounds;
- (NSIndexSet *)indexesForItemsInRect:(CGRect)rect;     // returns nil if rect is outside list

- (CGRect)visibleRect;
- (NSArray *)visibleViews;
- (NSIndexSet *)indexesForVisibleItems;

- (void)scrollToItemAtIndex:(NSUInteger)index atScrollPosition:(JTListViewScrollPosition)scrollPosition animated:(BOOL)animated;

// smart paging
- (void)goBack:(BOOL)animated;
- (void)goForward:(BOOL)animated;

- (UIView *)dequeueReusableView;   // similar to UITableView's dequeueReusableCellWithIdentifier:

@end


@interface JTListViewController : UIViewController <JTListViewDataSource, JTListViewDelegate> 

@property (nonatomic, retain) IBOutlet JTListView *listView;

@end

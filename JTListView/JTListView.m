//
//  JTListView.m
//  JTListView
//
//  Created by Jun on 5/6/11.
//  Copyright 2011 Jun Tanaka. All rights reserved.
//

#import "JTListView.h"


BOOL JTListViewLayoutIsHorizontal(JTListViewLayout layout)
{
    return (layout == JTListViewLayoutLeftToRight || layout == JTListViewLayoutRightToLeft);
}

BOOL JTListViewLayoutIsVertical(JTListViewLayout layout)
{
    return (layout == JTListViewLayoutTopToBottom || layout == JTListViewLayoutBottomToTop);
}


#pragma mark -
@interface JTListView (Private)

- (BOOL)isHorizontalLayout;
- (BOOL)isVerticalLayout;

- (void)sharedInit;

- (void)layoutItemRects;
- (void)layoutVisibleItems;
- (void)loadItemAtIndex:(NSUInteger)index;
- (void)loadItemAtIndexes:(NSIndexSet *)indexes;
- (void)recycleView:(UIView *)view;
- (void)recycleItemAtIndexes:(NSIndexSet *)indexes;

- (NSUInteger)leftItemIndex;
- (NSUInteger)rightItemIndex;
- (NSUInteger)upperItemIndex;
- (NSUInteger)lowerItemIndex;

- (void)goLeft:(BOOL)animated;
- (void)goRight:(BOOL)animated;
- (void)goUp:(BOOL)animated;
- (void)goDown:(BOOL)animated;

@end


#pragma mark -
@implementation JTListView

@synthesize dataSource      = _dataSource;
@synthesize layout          = _layout;
@synthesize itemWidth       = _itemWidth;
@synthesize itemHeight      = _itemHeight;
@synthesize gapBetweenItems = _gapBetweenItems;
@synthesize visibleInsets   = _visibleInsets;

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"itemWidth"];
    [self removeObserver:self forKeyPath:@"itemHeight"];
    [self removeObserver:self forKeyPath:@"gapBetweenItems"];
    
    [_itemRects release],      _itemRects      = nil;
    [_visibleViews release],   _visibleViews   = nil;
    [_reuseableViews release], _reuseableViews = nil;
    
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self sharedInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame layout:JTListViewLayoutLeftToRight];
}

- (id)initWithFrame:(CGRect)frame layout:(JTListViewLayout)layout;
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self sharedInit];
        [self setLayout:layout];
    }
    return self;
}


#pragma mark - JTListView (Private)

- (BOOL)isHorizontalLayout
{
    return JTListViewLayoutIsHorizontal(_layout);
}

- (BOOL)isVerticalLayout
{
    return JTListViewLayoutIsVertical(_layout);
}

- (void)sharedInit
{    
    _itemRects       = [[NSMutableArray alloc] init];
    _visibleRange    = NSMakeRange(0, 0);
    _visibleViews    = [[NSMutableArray alloc] init];
    _reuseableViews  = [[NSMutableSet alloc] init];
    _itemWidth       = 44.0;
    _itemHeight      = 44.0;
    _gapBetweenItems = 0.0;
    _visibleInsets   = UIEdgeInsetsZero;
    
    self.directionalLockEnabled = YES;
    
    [self addObserver:self forKeyPath:@"itemWidth" options:0 context:nil];
    [self addObserver:self forKeyPath:@"itemHeight" options:0 context:nil];
    [self addObserver:self forKeyPath:@"gapBetweenItems" options:0 context:nil];
    
    [self setLayout:JTListViewLayoutLeftToRight];
}

- (void)layoutItemRects
{
    __block CGPoint contentOffset = CGPointZero;
    __block CGSize  contentSize   = CGSizeZero;

    NSEnumerationOptions enumerationOptions;
    
    if (_layout == JTListViewLayoutLeftToRight || _layout == JTListViewLayoutTopToBottom)
    {
        enumerationOptions = 0;
    }
    else if (_layout == JTListViewLayoutRightToLeft || _layout == JTListViewLayoutBottomToTop)
    {
        enumerationOptions = NSEnumerationReverse;
    }
    
    void(^contentUpdater)(CGRect);
    
    if ([self isHorizontalLayout])
    {
        contentUpdater = ^(CGRect itemRect)
        {
            CGFloat step = itemRect.size.width + _gapBetweenItems;
            contentOffset.x += step;
            contentSize.width += step;
        };
    }
    else if ([self isVerticalLayout])
    {
        contentUpdater = ^(CGRect itemRect)
        {
            CGFloat step = itemRect.size.height + _gapBetweenItems;
            contentOffset.y += step;
            contentSize.height += step;
        };
    }
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfItems])];
    
    [indexSet enumerateIndexesWithOptions:enumerationOptions usingBlock:^(NSUInteger idx, BOOL *stop)
    {
        CGRect itemRect = [[_itemRects objectAtIndex:idx] CGRectValue];
        itemRect.origin.x = contentOffset.x;
        itemRect.origin.y = contentOffset.y;
        [_itemRects replaceObjectAtIndex:idx withObject:[NSValue valueWithCGRect:itemRect]];
        contentUpdater(itemRect);
    }];
    
    if ([self isHorizontalLayout])
    {
        contentSize.width -= _gapBetweenItems;
        
        if (contentSize.width < self.frame.size.width)
        {
            CGFloat gap = self.frame.size.width - contentSize.width;
            contentSize.width = self.frame.size.width;
            
            if (_layout == JTListViewLayoutRightToLeft)
            {
                [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
                {
                    CGRect itemRect = [[_itemRects objectAtIndex:idx] CGRectValue];
                    itemRect.origin.x += gap;
                    [_itemRects replaceObjectAtIndex:idx withObject:[NSValue valueWithCGRect:itemRect]];
                }];
            }
        }
    }
    else if ([self isVerticalLayout])
    {
        contentSize.height -= _gapBetweenItems;
        
        if (contentSize.height < self.frame.size.height)
        {
            CGFloat gap = self.frame.size.height - contentSize.height;
            contentSize.height = self.frame.size.height;
            
            if (_layout == JTListViewLayoutBottomToTop)
            {
                [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
                {
                    CGRect itemRect = [[_itemRects objectAtIndex:idx] CGRectValue];
                    itemRect.origin.y += gap;
                    [_itemRects replaceObjectAtIndex:idx withObject:[NSValue valueWithCGRect:itemRect]];
                }];
            }
        }
    }
    
    self.contentSize = contentSize;
    
    [self layoutVisibleItems];
}

- (void)layoutVisibleItems
{            
    NSIndexSet *oldVisibleIndexes = [NSIndexSet indexSetWithIndexesInRange:_visibleRange];
    NSIndexSet *newVisibleIndexes = [self indexesForItemsInRect:[self visibleRect]];
    
    if (![oldVisibleIndexes isEqualToIndexSet:newVisibleIndexes])
    {
        NSIndexSet *indexesForRecycle = [oldVisibleIndexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop)
        {
            return ![newVisibleIndexes containsIndex:idx];
        }];
        [self recycleItemAtIndexes:indexesForRecycle];
        
        NSUInteger firstIndex = [newVisibleIndexes firstIndex];
        NSUInteger lastIndex = [newVisibleIndexes lastIndex];
        _visibleRange = (!newVisibleIndexes) ? NSMakeRange(0, 0) : NSMakeRange(firstIndex, lastIndex - firstIndex + 1);
        
        NSIndexSet *indexesForLoad = [newVisibleIndexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop)
        {
            return ![oldVisibleIndexes containsIndex:idx];
        }];
        [self loadItemAtIndexes:indexesForLoad];
    }
    
    BOOL animationsEnabled = [UIView areAnimationsEnabled];

    [newVisibleIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
    {
        UIView *view = [self viewForItemAtIndex:idx];
        CGRect itemRect = [self rectForItemAtIndex:idx];
        
        if (!view.subviews || !CGPointEqualToPoint(view.frame.origin, itemRect.origin))
        {
            [UIView setAnimationsEnabled:NO];
        }
        
        if (!CGRectEqualToRect(view.frame, itemRect))
        {
            view.frame = itemRect;
        }
        
        if (!view.superview)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(listView:willDisplayView:forItemAtIndex:)])
            {
                [self.delegate listView:self willDisplayView:view forItemAtIndex:idx];
            }
            [self insertSubview:view atIndex:1];            
        }
        
        [UIView setAnimationsEnabled:animationsEnabled];
    }];
}

- (void)loadItemAtIndex:(NSUInteger)index
{
    UIView *view = [self.dataSource listView:self viewForItemAtIndex:index];
    [_visibleViews insertObject:view atIndex:index - _visibleRange.location];
}

- (void)loadItemAtIndexes:(NSIndexSet *)indexes
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
    {
        [self loadItemAtIndex:idx];
    }];
}

- (void)recycleView:(UIView *)view
{
    if (!view)
    {
        return;
    }
    
    [view retain];
    [view removeFromSuperview];
    [_visibleViews removeObject:view];
    [_reuseableViews addObject:view];
    [view release];
}

- (void)recycleItemAtIndexes:(NSIndexSet *)indexes
{
    [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop)
    {
        [self recycleView:[self viewForItemAtIndex:idx]];
    }];
}

- (NSUInteger)leftItemIndex
{
    NSUInteger centerItemIndex = [self indexForItemAtCenterOfBounds];
    
    if (_layout == JTListViewLayoutLeftToRight)
    {
        if (centerItemIndex == 0)
        {
            return NSNotFound;
        }
        return centerItemIndex - 1;
    }
    else if (_layout == JTListViewLayoutRightToLeft)
    {
        if (centerItemIndex == [self numberOfItems] - 1)
        {
            return NSNotFound;
        }
        return centerItemIndex + 1;
    }
    
    return NSNotFound;
}

- (NSUInteger)rightItemIndex
{
    NSUInteger centerItemIndex = [self indexForItemAtCenterOfBounds];
    
    if (_layout == JTListViewLayoutLeftToRight)
    {
        if (centerItemIndex == [self numberOfItems] - 1)
        {
            return NSNotFound;
        }
        return centerItemIndex + 1;
    }
    else if (_layout == JTListViewLayoutRightToLeft)
    {
        if (centerItemIndex == 0)
        {
            return NSNotFound;
        }
        return centerItemIndex - 1;
    }
    
    return NSNotFound;
}

- (NSUInteger)upperItemIndex
{
    NSUInteger centerItemIndex = [self indexForItemAtCenterOfBounds];
    
    if (_layout == JTListViewLayoutTopToBottom)
    {
        if (centerItemIndex == 0)
        {
            return NSNotFound;
        }
        return centerItemIndex - 1;
    }
    else if (_layout == JTListViewLayoutBottomToTop)
    {
        if (centerItemIndex == [self numberOfItems] - 1)
        {
            return NSNotFound;
        }
        return centerItemIndex + 1;
    }
    
    return NSNotFound;
}

- (NSUInteger)lowerItemIndex
{
    NSUInteger centerItemIndex = [self indexForItemAtCenterOfBounds];
    
    if (_layout == JTListViewLayoutTopToBottom)
    {
        if (centerItemIndex == [self numberOfItems] - 1)
        {
            return NSNotFound;
        }
        return centerItemIndex + 1;
    }
    else if (_layout == JTListViewLayoutBottomToTop)
    {
        if (centerItemIndex == 0)
        {
            return NSNotFound;
        }
        return centerItemIndex - 1;
    }
    
    return NSNotFound;
}

- (void)goLeft:(BOOL)animated;
{    
    NSUInteger currentItemIndex = [self indexForItemAtCenterOfBounds];
    
    if (currentItemIndex == NSNotFound)
    {
        return;
    }
    
    CGPoint contentOffset;
    CGRect currentItemRect = [self rectForItemAtIndex:currentItemIndex];
    CGFloat currentItemMinX = CGRectGetMinX(currentItemRect);
    
    if (CGRectGetMinX(self.bounds) > currentItemMinX)
    {
        if (self.bounds.size.width > CGRectGetMinX(self.bounds) - currentItemMinX)
        {
            contentOffset = CGPointMake(currentItemMinX, self.contentOffset.y);
        }
        else
        {
            contentOffset = CGPointMake(self.contentOffset.x - self.bounds.size.width, self.contentOffset.y);
        }
        [self setContentOffset:contentOffset animated:animated];
    }
    else
    {
        NSUInteger nextItemIndex = [self leftItemIndex];
        [self scrollToItemAtIndex:nextItemIndex atScrollPosition:JTListViewScrollPositionCenterElseNone animated:animated];
    }
}

- (void)goRight:(BOOL)animated;
{
    NSUInteger currentItemIndex = [self indexForItemAtCenterOfBounds];
    
    if (currentItemIndex == NSNotFound)
    {
        return;
    }
    
    CGPoint contentOffset;
    CGRect currentItemRect = [self rectForItemAtIndex:currentItemIndex];
    CGFloat currentItemMaxX = CGRectGetMaxX(currentItemRect);
    
    if (CGRectGetMaxX(self.bounds) < currentItemMaxX)
    {
        if (self.bounds.size.width > currentItemMaxX - CGRectGetMaxX(self.bounds))
        {
            contentOffset = CGPointMake(currentItemMaxX - self.bounds.size.width, self.contentOffset.y);
        }
        else
        {
            contentOffset = CGPointMake(self.contentOffset.x + self.bounds.size.width, self.contentOffset.y);
        }
        [self setContentOffset:contentOffset animated:animated];
    }
    else
    {
        NSUInteger nextItemIndex = [self rightItemIndex];
        [self scrollToItemAtIndex:nextItemIndex atScrollPosition:JTListViewScrollPositionCenterElseNone animated:animated];
    }
}

- (void)goUp:(BOOL)animated;
{
    NSUInteger currentItemIndex = [self indexForItemAtCenterOfBounds];
    
    if (currentItemIndex == NSNotFound)
    {
        return;
    }
    
    CGPoint contentOffset;
    CGRect currentItemRect = [self rectForItemAtIndex:currentItemIndex];
    CGFloat currentItemMinY = CGRectGetMinY(currentItemRect);
    
    if (CGRectGetMinY(self.bounds) > currentItemMinY)
    {
        if (self.bounds.size.height > CGRectGetMinY(self.bounds) - currentItemMinY)
        {
            contentOffset = CGPointMake(self.contentOffset.x, currentItemMinY);
        }
        else
        {
            contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y - self.bounds.size.height);
        }
        [self setContentOffset:contentOffset animated:animated];
    }
    else
    {
        NSUInteger nextItemIndex = [self upperItemIndex];
        [self scrollToItemAtIndex:nextItemIndex atScrollPosition:JTListViewScrollPositionCenterElseNone animated:animated];
    }
}

- (void)goDown:(BOOL)animated;
{
    NSUInteger currentItemIndex = [self indexForItemAtCenterOfBounds];
    
    if (currentItemIndex == NSNotFound)
    {
        return;
    }
    
    CGPoint contentOffset;
    CGRect currentItemRect = [self rectForItemAtIndex:currentItemIndex];
    CGFloat currentItemMaxY = CGRectGetMaxY(currentItemRect);
    
    if (CGRectGetMaxY(self.bounds) < currentItemMaxY)
    {
        if (self.bounds.size.height > currentItemMaxY - CGRectGetMaxY(self.bounds))
        {
            contentOffset = CGPointMake(self.contentOffset.x, currentItemMaxY - self.bounds.size.height);
        }
        else
        {
            contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y + self.bounds.size.height);
        }
        [self setContentOffset:contentOffset animated:animated];
    }
    else
    {
        NSUInteger nextItemIndex = [self lowerItemIndex];
        [self scrollToItemAtIndex:nextItemIndex atScrollPosition:JTListViewScrollPositionCenter animated:animated];
    }
}


#pragma mark - JTListView (Public)

- (id <JTListViewDelegate>)delegate
{
    return (id <JTListViewDelegate>)[super delegate];
}

- (void)setDelegate:(id<JTListViewDelegate>)delegate
{
    [super setDelegate:delegate];
}

- (void)setLayout:(JTListViewLayout)layout
{
    NSUInteger indexCache = [self indexForItemAtCenterOfBounds];
    
    if (indexCache == NSNotFound || CGRectContainsRect(self.bounds, [self rectForItemAtIndex:0]))
    {
        indexCache = 0;
    }
    else if (CGRectContainsRect(self.bounds, [self rectForItemAtIndex:[self numberOfItems] - 1]))
    {
        indexCache = [self numberOfItems] - 1;
    }
        
    _layout = layout;
    
    if (JTListViewLayoutIsHorizontal(layout))
    {
        self.alwaysBounceHorizontal = YES;
        self.alwaysBounceVertical = NO;
    }
    else if (JTListViewLayoutIsVertical(layout))
    {
        self.alwaysBounceHorizontal = NO;
        self.alwaysBounceVertical = YES;
    }
    
    [self reloadData];
    [self scrollToItemAtIndex:indexCache atScrollPosition:JTListViewScrollPositionCenter animated:NO];
    [self flashScrollIndicators];
}

- (void)reloadData
{
    if (!self.dataSource)
    {
        return;
    }
    
    for (UIView *view in [_visibleViews reverseObjectEnumerator])
    {
        [self recycleView:view];
    }
    
    _visibleRange = NSMakeRange(0, 0);
    [_itemRects removeAllObjects];
    
    NSUInteger numberOfItems = [self.dataSource numberOfItemsInListView:self];
    
    for (int i = 0; i < numberOfItems; i ++)
    {
        [_itemRects addObject:[NSValue valueWithCGRect:CGRectNull]];
    }
    
    [self updateItemSizes];
}

- (void)reloadItemsAtIndexes:(NSIndexSet *)indexes
{
    if (!self.dataSource)
    {
        return;
    }
    
    [self recycleItemAtIndexes:indexes];
    [self updateItemSizesAtIndexes:indexes];
}

- (void)updateItemSizes
{
    NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfItems])];
    [self updateItemSizesAtIndexes:allIndexes];
}

- (void)updateItemSizesAtIndexes:(NSIndexSet *)indexes
{    
    CGSize(^sizeForItemAtIndex)(NSUInteger);
    
    if ([self isHorizontalLayout])
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(listView:widthForItemAtIndex:)])
        {
            sizeForItemAtIndex = ^CGSize(NSUInteger idx)
            {
                return CGSizeMake([self.delegate listView:self widthForItemAtIndex:idx], self.frame.size.height); 
            };
        }
        else
        {
            sizeForItemAtIndex = ^CGSize(NSUInteger idx)
            {
                return CGSizeMake(_itemWidth, self.frame.size.height); 
            };
        }
    }
    else if ([self isVerticalLayout])
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(listView:heightForItemAtIndex:)])
        {
            sizeForItemAtIndex = ^CGSize(NSUInteger idx)
            {
                return CGSizeMake(self.frame.size.width, [self.delegate listView:self heightForItemAtIndex:idx]); 
            };
        }
        else
        {
            sizeForItemAtIndex = ^CGSize(NSUInteger idx)
            {
                return CGSizeMake(self.frame.size.width, _itemHeight); 
            };
        }
    }
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
    {
        CGRect itemRect = [self rectForItemAtIndex:idx];
        itemRect.size = sizeForItemAtIndex(idx);
        [_itemRects replaceObjectAtIndex:idx withObject:[NSValue valueWithCGRect:itemRect]];
    }];
    
    [self layoutItemRects];
}

- (NSUInteger)numberOfItems
{
    return [_itemRects count];
}

- (CGRect)rectForItemAtIndex:(NSUInteger)index
{
    if (index < [_itemRects count])
    {
        return [[_itemRects objectAtIndex:index] CGRectValue];
    }
    return CGRectNull;
}

- (UIView *)viewForItemAtIndex:(NSUInteger)index
{
    if (index - _visibleRange.location < [_visibleViews count])
    {
        return [_visibleViews objectAtIndex:index - _visibleRange.location];
    }
    return nil;
}

- (NSUInteger)indexForView:(UIView *)view
{
    if ([_visibleViews containsObject:view])
    {
        return [_visibleViews indexOfObject:view] + _visibleRange.location;
    }
    return NSNotFound;
}

- (NSUInteger)indexForItemAtPoint:(CGPoint)point
{
    NSIndexSet *indexes = [self indexesForItemsInRect:CGRectMake(point.x, point.y, 1, 1)];
    if (indexes)
    {
        return [indexes lastIndex];
    }
    return NSNotFound;
}

- (NSUInteger)indexForItemAtCenterOfBounds
{
    return [self indexForItemAtPoint:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
}

- (NSIndexSet *)indexesForItemsInRect:(CGRect)rect
{
    if ([self numberOfItems] == 0)
    {
        return nil;
    }
    
    CGRect firstItemRect = [self rectForItemAtIndex:0];
    
    NSUInteger minIndex = 0;
    NSUInteger maxIndex = [self numberOfItems] - 1;
    
    while (YES)
    {
        NSUInteger centerIndex = minIndex + (maxIndex - minIndex) / 2;
        CGRect centerItemRect = [self rectForItemAtIndex:centerIndex];
        
        if (CGRectIntersectsRect(centerItemRect, rect))
        {
            NSUInteger firstIndex = centerIndex;
            NSUInteger lastIndex = centerIndex;
            
            while (firstIndex > 0 && CGRectIntersectsRect([self rectForItemAtIndex:firstIndex - 1], rect))
            {
                firstIndex --;
            }
            while (lastIndex < [self numberOfItems] - 1 && CGRectIntersectsRect([self rectForItemAtIndex:lastIndex + 1], rect))
            {
                lastIndex ++;
            }
            
            NSRange indexRange = NSMakeRange(firstIndex, lastIndex - firstIndex + 1);
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:indexRange];
            return indexes;
        }
        else if (minIndex == maxIndex)
        {
            return nil;
        }
        else
        {
            if (!CGRectIntersectsRect(CGRectUnion(firstItemRect, centerItemRect), rect))
            {
                minIndex = centerIndex + 1;
            }
            else
            {
                maxIndex = centerIndex - 1;
            }
        }
    }
    
    return nil;
}

- (CGRect)visibleRect
{
    return UIEdgeInsetsInsetRect(self.bounds, _visibleInsets);
}

- (NSArray *)visibleViews
{
    return _visibleViews;
}

- (NSIndexSet *)indexesForVisibleItems
{
    return [NSIndexSet indexSetWithIndexesInRange:_visibleRange];
}

- (void)scrollToItemAtIndex:(NSUInteger)index atScrollPosition:(JTListViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    if (index >= [self numberOfItems])
    {
        return;
    }
    
    CGPoint offset;
    CGRect itemRect = [self rectForItemAtIndex:index];
    
    if (scrollPosition == JTListViewScrollPositionNone)
    {
        if (CGRectContainsRect(itemRect, self.bounds))
        {
            return;
        }
        else if ([self isHorizontalLayout])
        {
            if (itemRect.size.width == self.bounds.size.width || 
                (itemRect.size.width < self.bounds.size.width && CGRectGetMidX(itemRect) < CGRectGetMidX(self.bounds)) ||
                (itemRect.size.width > self.bounds.size.width && CGRectGetMidX(itemRect) > CGRectGetMidX(self.bounds)))
            {
                offset = CGPointMake(CGRectGetMinX(itemRect), self.contentOffset.y);
                [self setContentOffset:offset animated:animated];
            }
            else if ((itemRect.size.width < self.bounds.size.width && CGRectGetMidX(itemRect) > CGRectGetMidX(self.bounds)) ||
                     (itemRect.size.width > self.bounds.size.width && CGRectGetMidX(itemRect) < CGRectGetMidX(self.bounds)))
            {
                offset = CGPointMake(CGRectGetMaxX(itemRect) - self.bounds.size.width, self.contentOffset.y);
                [self setContentOffset:offset animated:animated];
            }
        }
        else if ([self isVerticalLayout])
        {
            if (itemRect.size.height == self.bounds.size.height ||
                (itemRect.size.height < self.bounds.size.height && CGRectGetMidY(itemRect) < CGRectGetMidY(self.bounds)) ||
                (itemRect.size.height > self.bounds.size.height && CGRectGetMidY(itemRect) > CGRectGetMidY(self.bounds)))
            {
                offset = CGPointMake(self.contentOffset.x, CGRectGetMinY(itemRect));
                [self setContentOffset:offset animated:animated];
            }
            else if ((itemRect.size.height < self.bounds.size.height && CGRectGetMidY(itemRect) > CGRectGetMidY(self.bounds)) ||
                     (itemRect.size.height > self.bounds.size.height && CGRectGetMidY(itemRect) < CGRectGetMidY(self.bounds)))
            {
                offset = CGPointMake(self.contentOffset.x, CGRectGetMaxY(itemRect) - self.bounds.size.height);
                [self setContentOffset:offset animated:animated];
            }
        }
    }
    else if (scrollPosition == JTListViewScrollPositionCenter)
    {
        if ([self isHorizontalLayout])
        {
            offset = CGPointMake((itemRect.origin.x - (self.frame.size.width - itemRect.size.width) / 2), self.contentOffset.y);
            if (offset.x < 0)
            {
                offset.x = 0;
            }
            if (offset.x > self.contentSize.width - self.frame.size.width)
            {
                offset.x = self.contentSize.width - self.frame.size.width;
            }
        }
        else if ([self isVerticalLayout])
        {
            offset = CGPointMake(self.contentOffset.x, itemRect.origin.y - (self.frame.size.height - itemRect.size.height) / 2);
            if (offset.y < 0)
            {
                offset.y = 0;
            }
            if (offset.y > self.contentSize.height - self.frame.size.height)
            {
                offset.y = self.contentSize.height - self.frame.size.height;
            }
        }
        [self setContentOffset:offset animated:animated];
    }
    else if (scrollPosition == JTListViewScrollPositionCenterElseNone)
    {
        if (([self isHorizontalLayout] && itemRect.size.width <= self.bounds.size.width) || 
            ([self isVerticalLayout] && itemRect.size.height <= self.bounds.size.height))
        {
            [self scrollToItemAtIndex:index atScrollPosition:JTListViewScrollPositionCenter animated:animated];
        }
        else
        {
            [self scrollToItemAtIndex:index atScrollPosition:JTListViewScrollPositionNone animated:animated];
        }
    }
}

- (void)goBack:(BOOL)animated
{
    switch (_layout)
    {
        case JTListViewLayoutLeftToRight: [self goLeft:animated];  break;
        case JTListViewLayoutRightToLeft: [self goRight:animated]; break;
        case JTListViewLayoutTopToBottom: [self goUp:animated];    break;
        case JTListViewLayoutBottomToTop: [self goDown:animated];  break;
    }
}

- (void)goForward:(BOOL)animated
{
    switch (_layout)
    {
        case JTListViewLayoutLeftToRight: [self goRight:animated]; break;
        case JTListViewLayoutRightToLeft: [self goLeft:animated];  break;
        case JTListViewLayoutTopToBottom: [self goDown:animated];  break;
        case JTListViewLayoutBottomToTop: [self goUp:animated];    break;
    }
}

- (UIView *)dequeueReusableView
{
    UIView *reuseableView = [_reuseableViews anyObject];
    if (reuseableView)
    {
        [[reuseableView retain] autorelease];
        [_reuseableViews removeObject:reuseableView];
    }
    return reuseableView;
}


#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    static CGSize frameSizeCache = {0.0, 0.0};
    
    if (CGSizeEqualToSize(frameSizeCache, CGSizeZero))
    {
        frameSizeCache = self.frame.size;
    }
    
    if (!CGSizeEqualToSize(self.frame.size, frameSizeCache))
    {
        [self updateItemSizes];
        frameSizeCache = self.frame.size;
    }
    else
    {
        [self layoutVisibleItems];
    }
}


#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self)
    {
        if ([keyPath isEqualToString:@"itemWidth"] || [keyPath isEqualToString:@"itemHeight"])
        {
            [self updateItemSizes];
        }
        else if ([keyPath isEqualToString:@"gapBetweenItems"])
        {
            [self layoutItemRects];
        }
    }
}

@end


#pragma mark -
@implementation JTListViewController

@synthesize listView = _listView;

- (void)loadView
{
    self.view = self.listView = [[[JTListView alloc] init] autorelease];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.listView)
    {
        self.listView.dataSource = self;
        self.listView.delegate = self;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    if (self.listView)
    {
        self.listView.dataSource = nil;
        self.listView.delegate = nil;
        self.listView = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([self.listView numberOfItems] == 0)
    {
        [self.listView reloadData];
    }
}


#pragma mark - JTListViewDataSource (Required)

- (NSUInteger)numberOfItemsInListView:(JTListView *)listView
{
    return 0;
}

- (UIView *)listView:(JTListView *)listView viewForItemAtIndex:(NSUInteger)index
{
    UIView *view = [listView dequeueReusableView];
    if (!view)
    {
        view = [[[UIView alloc] init] autorelease];
    }
    return view;
}

@end

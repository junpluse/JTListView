//
//  JTListViewDemoController.m
//  JTListView
//
//  Created by Jun on 5/8/11.
//  Copyright 2011 Jun Tanaka. All rights reserved.
//

#import "JTListViewDemoController.h"


@implementation JTListViewDemoController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //self.listView.itemWidth = 80.0;
    //self.listView.itemHeight = 80.0;
    //self.listView.gapBetweenItems = 44.0;
    //self.listView.visibleInsets = UIEdgeInsetsMake(-256, -256, -256, -256);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)presentDirectionSelector:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Direction" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Left to Right", @"Right to Left", @"Top to Bottom", @"Bottom to Top", nil];
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (IBAction)goBack:(id)sender
{
    [self.listView goBack:YES];
}

- (IBAction)goForward:(id)sender
{
    [self.listView goForward:YES];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    JTListViewLayout layout;
    switch (buttonIndex)
    {
        case 0: layout = JTListViewLayoutLeftToRight; break;
        case 1: layout = JTListViewLayoutRightToLeft; break;
        case 2: layout = JTListViewLayoutTopToBottom; break;
        case 3: layout = JTListViewLayoutBottomToTop; break;
        default: return; break;
    }
    self.listView.layout = layout;
}


#pragma mark - JTListViewDataSource

- (NSUInteger)numberOfItemsInListView:(JTListView *)listView
{
    return 100;
}

- (UIView *)listView:(JTListView *)listView viewForItemAtIndex:(NSUInteger)index
{
    UIView *view = [listView dequeueReusableView];
    
    if (!view) {
        view = [[[UIView alloc] init] autorelease];
        
        UILabel *label = [[[UILabel alloc] initWithFrame:view.bounds] autorelease];
        label.center = view.center;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:24.0];
        label.textAlignment = UITextAlignmentCenter;
        label.tag = 1;
        
        [view addSubview:label];
    }
    
    view.backgroundColor = [UIColor colorWithHue:(float)(index % 7) / 7.0 saturation:0.75 brightness:1.0 alpha:1.0];
    [(UILabel *)[view viewWithTag:1] setText:[NSString stringWithFormat:@"#%u", index]];
    
    return view;
}


#pragma mark - JTListViewDelegate

- (CGFloat)listView:(JTListView *)listView widthForItemAtIndex:(NSUInteger)index
{
    return (CGFloat)(index % 7 * 60 + 60);
}

- (CGFloat)listView:(JTListView *)listView heightForItemAtIndex:(NSUInteger)index
{
    return (CGFloat)(index % 7 * 60 + 60);
}

@end

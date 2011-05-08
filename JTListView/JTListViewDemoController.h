//
//  JTListViewDemoController.h
//  JTListView
//
//  Created by Jun on 5/8/11.
//  Copyright 2011 Jun Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JTListView.h"


@interface JTListViewDemoController : JTListViewController <UIActionSheetDelegate>

- (IBAction)presentDirectionSelector:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;

@end

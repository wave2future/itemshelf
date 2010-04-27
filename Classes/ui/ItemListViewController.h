// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
/*
  ItemShelf for iPhone/iPod touch

  Copyright (c) 2008, ItemShelf Development Team. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer. 

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution. 

  3. Neither the name of the project nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission. 

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// アイテム一覧を表示するビューコントローラ
//   History, iWant, iHave で共通に使用するクラス

#import <UIKit/UIKit.h>
#import "Common.h"
#import "ShelfListViewController.h"
#import "Shelf.h"
#import "Item.h"
#import "ItemListModel.h"
#import "StringArray.h"
#import "GenSelectListViewController.h"

/**
   Extended UITableView class with touch event handlers.
   
   This is needed to get X-coordinate for 4-items per row mode.
*/
@interface UITableViewWithTouchEvent : UITableView

@end

@interface ItemListViewController : UIViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, 
     ItemDelegate, GenSelectListViewDelegate, UIActionSheetDelegate,
     UISplitViewControllerDelegate>
{
    UITableViewWithTouchEvent *tableView;
    UISearchBar *searchBar;

    IBOutlet UIToolbar *toolbar;
    IBOutlet UIBarButtonItem *scanButton;
    IBOutlet UIBarButtonItem *filterButton;

    ItemListModel *model;

    // iPad
    IBOutlet ShelfListViewController *splitShelfListViewController;
    UIPopoverController *popoverController;
}

@property(nonatomic,retain) UIPopoverController *popoverController;

- (void)reload;
- (void)setShelf:(Shelf*)shelf;
- (void)updateTitle;
- (void)setFilter:(NSString *)filter;

- (IBAction)toggleSearchBar:(id)sender;
- (void)showSearchBar;
- (void)hideSearchBar;
- (IBAction)toggleCellView:(id)sender;
- (IBAction)scanButtonTapped:(id)sender;
- (IBAction)filterButtonTapped:(id)sender;
- (IBAction)sortButtonTapped:(id)sender;

- (int)_calcNumMultiItemsPerLine;

@end

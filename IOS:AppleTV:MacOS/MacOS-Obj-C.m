//
//  TVPCatchUpViewController.m
//  TVPlayer
//
//  Created by Razvan on 11/04/16.
//  Copyright © 2016 iColdo. All rights reserved.
//

#import "TVPCatchUpViewController.h"
#import "NSColor+Hex.h"
#import "TVPDataManager.h"
#import "TVPSettings.h"
#import "TVPCatchUpCategoryTableCellView.h"
#import "TVPCatchUpCategoryTableRowView.h"
#import "TVPProgram.h"
#import "TVPChannel.h"
#import <Masonry.h>
#import "TVPCatchUpProgramCollectionViewItem.h"
#import "TVPButton.h"
#import "TVPImageView.h"
#import "NSImageView+AFNetworking.h"
#import "AppDelegate.h"
#import "TVPNetworkManager.h"

#define PROGRAM_DETAILS_CONTAINER_HEIGHT_OPEN       340.0
#define PROGRAM_DETAILS_CONTAINER_HEIGHT_CLOSED     0.0

@interface TVPCatchUpViewController ()
<NSTableViewDelegate, NSTableViewDataSource,
NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource>

@property (weak) IBOutlet NSView *categoriesContainerView;
@property (weak) IBOutlet NSTableView *categoriesTableView;
@property (weak) IBOutlet NSTextField *categoriesTitleTextField;
@property (weak) IBOutlet NSView *categoriesTitleSeparatorView;

@property (weak) IBOutlet NSView *programsContainerView;
@property (weak) IBOutlet NSCollectionView *programsCollectionView;

@property (nonatomic, strong) TVPCategory *selectedCategory;
@property (nonatomic, strong) TVPProgram *selectedProgram;

@property (nonatomic, assign) BOOL showingProgramDetails;

@property (weak) IBOutlet NSView *programDetailsContainerView;
@property (weak) IBOutlet NSLayoutConstraint *programDetailsContainerViewHeightLayout;
@property (weak) IBOutlet TVPImageView *programDetailsChannelLogoImageView;
@property (weak) IBOutlet TVPImageView *programDetailsThumbnailImageView;
@property (weak) IBOutlet NSView *programDetailsPaidTypeContainerView;
@property (weak) IBOutlet NSTextField *programDetailsPaidTypeTextField;
@property (weak) IBOutlet NSTextField *programDetailsTitleTextField;
@property (weak) IBOutlet NSTextField *programDetailsDetailsTextField;
@property (weak) IBOutlet NSScrollView *programDetailsDescriptionScrollView;
@property (nonatomic, readonly) NSTextView *programDetailsDescriptionTextView;
@property (weak) IBOutlet NSLayoutConstraint *programDetailsDescriptionScrollWidthConstraint;
@property (weak) IBOutlet NSTextField *programDetailsCategoryTextField;
@property (weak) IBOutlet NSView *programDetailsSeparatorView;
@property (weak) IBOutlet NSButton *playCurrentProgramButton;

@property (weak) IBOutlet NSView *tryPlusContainerView;
@property (weak) IBOutlet NSView *needPlusContainerView;
@property (weak) IBOutlet NSTextField *needPlusTextField;
@property (weak) IBOutlet TVPButton *tryPlusButton;

- (IBAction)playCurrentProgramClicked:(id)sender;


@end

@implementation TVPCatchUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor colorWithHex:@"#fafafa"].CGColor;
    
    
    self.categoriesTableView.enclosingScrollView.automaticallyAdjustsContentInsets = NO;
    self.categoriesTableView.enclosingScrollView.contentInsets = NSEdgeInsetsMake(10, 0, 20, 0);
    [[self.categoriesTableView.enclosingScrollView contentView] scrollToPoint:NSMakePoint(0, -10)];
    
    
    self.categoriesContainerView.wantsLayer = YES;
    self.categoriesContainerView.layer.backgroundColor = [NSColor colorWithHex:@"#f5f5f5"].CGColor;
    
    self.categoriesTitleTextField.textColor = [NSColor colorWithHex:@"#7e7e7e"];
    self.categoriesTitleSeparatorView.wantsLayer = YES;
    self.categoriesTitleSeparatorView.layer.backgroundColor = [NSColor colorWithHex:@"#a8a8a8"].CGColor;
    
    
    self.programsContainerView.wantsLayer = YES;
    self.programsContainerView.layer.backgroundColor = [NSColor colorWithHex:@"#fafafa"].CGColor;
    
    
    self.programDetailsContainerViewHeightLayout.constant = PROGRAM_DETAILS_CONTAINER_HEIGHT_CLOSED;
    self.programDetailsSeparatorView.wantsLayer = YES;
    self.programDetailsSeparatorView.layer.backgroundColor = [NSColor colorWithHex:@"#e2e2e2"].CGColor;
    
    
    [self.programDetailsDescriptionTextView setFont:[NSFont fontWithName:@"ProximaNova-Regular" size:16]];
    

    self.tryPlusButton.backgroundColor = [NSColor whiteColor];
    self.tryPlusButton.layer.cornerRadius = 3.0;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    self.tryPlusButton.attributedTitle = [[NSAttributedString alloc] initWithString:@"Try PLUS"
                                                                         attributes:@{NSForegroundColorAttributeName : [NSColor colorWithHex:@"#db3291"],
                                                                                      NSFontAttributeName : [NSFont fontWithName:@"ProximaNova-Regular" size:13],
                                                                                      NSParagraphStyleAttributeName : paragraphStyle}];
    
    
    self.tryPlusContainerView.wantsLayer = YES;
    self.tryPlusContainerView.layer.backgroundColor = [NSColor colorWithHex:@"#00000030"].CGColor;
    self.needPlusContainerView.wantsLayer = YES;
    self.needPlusContainerView.layer.backgroundColor = [NSColor colorWithHex:@"#db329180"].CGColor;
    NSMutableAttributedString *needPlusAttributedString = [[NSMutableAttributedString alloc] init];
    [needPlusAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"You need " attributes:@{NSForegroundColorAttributeName : [NSColor whiteColor],
                                                                                                                         NSFontAttributeName : [NSFont fontWithName:@"ProximaNova-Regular" size:13]}]];
    [needPlusAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"TVPlayer Plus" attributes:@{NSForegroundColorAttributeName : [NSColor whiteColor],
                                                                                                                          NSFontAttributeName : [NSFont fontWithName:@"ProximaNova-Bold" size:13]}]];
    [needPlusAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" to watch this!" attributes:@{NSForegroundColorAttributeName : [NSColor whiteColor],
                                                                                                                          NSFontAttributeName : [NSFont fontWithName:@"ProximaNova-Regular" size:13]}]];
    self.needPlusTextField.attributedStringValue = needPlusAttributedString;

    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCategoryProgramsChanged:)
                                                 name:TVPNotificationCatchUpProgramsChanged
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewCategory:)
                                                 name:TVPNotificationCatchUpNewCategory
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleResize:) name:NSWindowDidResizeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoginStateChanged:) name:TVPNotificationLoginStateChanged object:nil];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [MPGoogleAnalyticsTracker trackScreen:@"Catch Up View"];
    
    if (!self.selectedCategory) {
        [self.categoriesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        self.selectedCategory = [[TVPDataManager sharedInstance].catchUpCategories objectAtIndex:0];
        [self.programsCollectionView reloadData];
    }
    
    if (self.timesAppeared == 1) {
        [[self.categoriesTableView.enclosingScrollView contentView] scrollToPoint:NSMakePoint(0, -10)];
    }
}

- (NSTextView *)programDetailsDescriptionTextView
{
    if (self.programDetailsDescriptionScrollView) {
        return (NSTextView *)self.programDetailsDescriptionScrollView.contentView.documentView;
    }
    
    return nil;
}

#pragma mark - NSTableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [TVPDataManager sharedInstance].catchUpCategories.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 32;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    TVPCatchUpCategoryTableRowView *rowView = (TVPCatchUpCategoryTableRowView *)[tableView makeViewWithIdentifier:@"TVPCatchUpCategoryTableRowView" owner:self];

    if (!rowView) {
        rowView = [[TVPCatchUpCategoryTableRowView alloc] init];
        rowView.identifier = @"TVPCatchUpCategoryTableRowView";
    }
    
    return rowView;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TVPCatchUpCategoryTableCellView *categoryCellView = (TVPCatchUpCategoryTableCellView *)[tableView makeViewWithIdentifier:@"TVPCatchUpCategoryTableCellView" owner:self];
    
    TVPCategory *category = [[TVPDataManager sharedInstance].catchUpCategories objectAtIndex:row];
    
    categoryCellView.category = category;
    
    return categoryCellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    
    if (tableView.selectedRow >= 0 && tableView.selectedRow < [TVPDataManager sharedInstance].catchUpCategories.count) {
        TVPCategory *category = [[TVPDataManager sharedInstance].catchUpCategories objectAtIndex:tableView.selectedRow];
        
        self.selectedCategory = category;
        
        [self.programsCollectionView reloadData];
        
        [[self.programsCollectionView.enclosingScrollView contentView] scrollToPoint:NSMakePoint(0, 0)];
        
        [self hideProgramDetails];
    }
}

#pragma mark - NSCollectionView

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.selectedCategory.categoryPrograms.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    TVPCatchUpProgramCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"TVPCatchUpProgramCollectionViewItem" forIndexPath:indexPath];
    
    TVPProgram *program = [self.selectedCategory.categoryPrograms objectAtIndex:indexPath.item];
    
    item.program = program;
    
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    NSIndexPath *indexPath = [indexPaths anyObject];
    
    TVPProgram *program = [self.selectedCategory.categoryPrograms objectAtIndex:indexPath.item];
    self.selectedProgram = program;
    
    [self loadDetailsForProgram:program];
    
    // Move the collection view lower to reveal the program details if it isn't already visible
    if (!self.showingProgramDetails) {
        [self showProgramDetails];
    }
}

#pragma mark - NSCollectionView Layout

- (NSSize)collectionView:(NSCollectionView *)collectionView
                  layout:(NSCollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSSize itemSize = NSMakeSize(0, 0);
    
    // Keep the aspect ratio from the design
    CGFloat aspectRatio = 240.0 / 170.0;
    
    CGFloat interitemSpacing = [self collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:indexPath.section];
    NSEdgeInsets edgeInsets = [self collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:indexPath.section];
    
    // Keep 3 equal columns when width < 1920, and 4 equal columns when width >= 1920
    CGFloat numberOfColumns = 3;
    if (self.view.frame.size.width >= 1920) {
        numberOfColumns = 4;
    }
    
    // Calculate the item size based on the number of columns and edge insets to keep them equal
    itemSize.width = floor(((collectionView.bounds.size.width - collectionView.enclosingScrollView.verticalScroller.bounds.size.width)
                            - edgeInsets.left
                            - edgeInsets.right
                            - (numberOfColumns - 1) * (interitemSpacing)) / numberOfColumns);
    
    // Have a limit of the item size where it stops growing with the window width and just increases the spacing instead
    if (numberOfColumns == 3) {
        if (itemSize.width > 367) {
            itemSize.width = 367;
        }
    }

    itemSize.height = floor(itemSize.width / aspectRatio);
    
    return itemSize;
}

- (NSEdgeInsets)collectionView:(NSCollectionView *)collectionView
                        layout:(NSCollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    if (self.showingProgramDetails) {
        return NSEdgeInsetsMake(10, 16, 10, 16);
    } else {
        return NSEdgeInsetsMake(41, 16, 41, 16);
    }
}

- (CGFloat)collectionView:(NSCollectionView *)collectionView
                   layout:(NSCollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

- (CGFloat)collectionView:(NSCollectionView *)collectionView
                   layout:(NSCollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

#pragma mark - Program Details

- (void)showProgramDetails
{
    self.showingProgramDetails = YES;
    [self.programsCollectionView.collectionViewLayout invalidateLayout];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        context.duration = 0.25;
        context.allowsImplicitAnimation = YES;
        self.programDetailsContainerViewHeightLayout.constant = PROGRAM_DETAILS_CONTAINER_HEIGHT_OPEN;
        [self.programsContainerView layoutSubtreeIfNeeded];
        NSUInteger selectedProgramIndex = [self.selectedCategory.categoryPrograms indexOfObject:self.selectedProgram];
        [self.programsCollectionView scrollToItemsAtIndexPaths:[NSSet setWithObjects:[NSIndexPath indexPathForItem:selectedProgramIndex inSection:0], nil]
                                                scrollPosition:NSCollectionViewScrollPositionCenteredVertically];
    } completionHandler:^{
        
    }];
}

- (void)hideProgramDetails
{
    self.showingProgramDetails = NO;
    [self.programsCollectionView.collectionViewLayout invalidateLayout];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        context.duration = 0.25;
        context.allowsImplicitAnimation = YES;
        self.programDetailsContainerViewHeightLayout.constant = PROGRAM_DETAILS_CONTAINER_HEIGHT_CLOSED;
        [self.programsContainerView layoutSubtreeIfNeeded];
    } completionHandler:nil];
    
    self.selectedProgram = nil;
}

- (void)loadDetailsForProgram:(TVPProgram *)program
{
    if (!program) {
        return;
    }
    
    [self.programDetailsThumbnailImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:program.programThumbnail]]
                                          placeholderImage:[[NSImage alloc] init]
                                                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSImage * _Nonnull image) {
                                                       if (image.representations.count == 0) {
                                                           // Load placeholder
                                                           self.programDetailsThumbnailImageView.image = [NSImage imageNamed:@"placeholder_live_tv_details_small"];
                                                       } else {
                                                           self.programDetailsThumbnailImageView.image = image;
                                                       }
                                                   } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                                                       NSLog(@"%@", error);
                                                   }];

    
    if ([program.programPackType isEqualToString:@"paid"]) {
        self.programDetailsPaidTypeContainerView.layer.backgroundColor = [NSColor colorWithHex:@"#db3291"].CGColor;
        self.programDetailsPaidTypeTextField.stringValue = program.programPackName;
    } else if ([program.programPackType isEqualToString:@"free"]) {
        self.programDetailsPaidTypeContainerView.layer.backgroundColor = [NSColor colorWithHex:@"#00b7ef"].CGColor;
        self.programDetailsPaidTypeTextField.stringValue = program.programPackName;
    }
    
    if (program.parentChannel) {
        self.programDetailsChannelLogoImageView.shouldScaleToAspectFill = YES;
        [self.programDetailsChannelLogoImageView setImageWithURL:[NSURL URLWithString:[[TVPSettings sharedInstance] channelTileLogoForChannelId:program.parentChannel.channelId]]];
    }
    
    self.programDetailsTitleTextField.stringValue = program.programTitle;
    
    NSMutableString *programDetailsString = [[NSMutableString alloc] init];
    if (program.programAvailableUntilDate) {
        NSTimeInterval timeLeft = program.programAvailableUntilTimestamp - [[NSDate date] timeIntervalSince1970];
        [programDetailsString appendString:[[TVPSettings sharedInstance] prettyTimeLeft:timeLeft]];
        
        if (program.programStartDate && program.programEndDate) {
            [programDetailsString appendString:@" | "];
        }
    }
    
    if (program.programStartDate && program.programEndDate) {
        NSTimeInterval duration = program.programEndTimestamp - program.programStartTimestamp;
        [programDetailsString appendString:[[TVPSettings sharedInstance] prettyDuration:duration]];
        
        if (program.programCategory && program.programCategory.length > 0) {
            [programDetailsString appendString:@" | "];
        }
    }
    
    if (program.programCategory && program.programCategory.length > 0) {
        [programDetailsString appendString:program.programCategory];
    }
    
    
    self.programDetailsDetailsTextField.stringValue = programDetailsString;

    
    CGFloat descriptionWidth = self.programDetailsContainerView.frame.size.width - 431.0;
    if (descriptionWidth > 659.0) {
        descriptionWidth = 659.0;
    }
    
    self.programDetailsDescriptionScrollWidthConstraint.constant = descriptionWidth;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.programDetailsDescriptionTextView.string = program.programDescription;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.programDetailsDescriptionTextView scrollToBeginningOfDocument:self];
        });
    });

    
    
    self.programDetailsCategoryTextField.stringValue = program.programCategory;
    
    if ([program.programPackType isEqualToString:@"paid"]) {
        if ([[TVPDataManager sharedInstance] hasAccessToProgram:program]) {
            [self hideTryPlus];
        } else {
            [self showTryPlus];
        }
    } else {
        [self hideTryPlus];
    }
}

- (void)showTryPlus
{
    self.tryPlusContainerView.hidden = NO;
    self.programDetailsPaidTypeContainerView.hidden = YES;
    self.playCurrentProgramButton.hidden = YES;
}

- (void)hideTryPlus
{
    self.tryPlusContainerView.hidden = YES;
    self.programDetailsPaidTypeContainerView.hidden = NO;
    self.playCurrentProgramButton.hidden = NO;
}

#pragma mark - Keeping Stuff In Sync

- (void)handleCategoryProgramsChanged:(NSNotification *)notification
{
    if (notification && notification.userInfo && notification.userInfo[@"category"]) {
        TVPCategory *categoryThatChanged = notification.userInfo[@"category"];
        
        NSUInteger categoryIndex = [[TVPDataManager sharedInstance].catchUpCategories indexOfObject:categoryThatChanged];
        NSInteger previousSelectedRowIndex = self.categoriesTableView.selectedRow;
        
        if (categoryThatChanged.categoryPrograms.count == 0) {
            if (categoryIndex == previousSelectedRowIndex) {
                // If the category we removed was selected, select the next or previous
                if (categoryIndex + 1 < [TVPDataManager sharedInstance].catchUpCategories.count) {
                    [self.categoriesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:categoryIndex + 1] byExtendingSelection:NO];
                } else if (categoryIndex - 1 > 0) {
                    [self.categoriesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:categoryIndex - 1] byExtendingSelection:NO];
                }
            }
            
            [self.categoriesTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:categoryIndex] withAnimation:NSTableViewAnimationSlideLeft];
            [[TVPDataManager sharedInstance].catchUpCategories removeObject:categoryThatChanged];
            self.selectedProgram = nil;
        } else {
            [self.categoriesTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:categoryIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            
            if (categoryIndex == previousSelectedRowIndex) {
                [self.programsCollectionView reloadData];
                
                if (self.selectedProgram) {
                    [self loadDetailsForProgram:self.selectedProgram];
                }
            }
        }
    }
}

- (void)handleNewCategory:(NSNotification *)notification
{
    if (notification && notification.userInfo && notification.userInfo[@"category"]) {
        TVPCategory *categoryThatChanged = notification.userInfo[@"category"];
        
        // New category
        NSUInteger newCategoryIndex = [[TVPDataManager sharedInstance].catchUpCategories indexOfObject:categoryThatChanged];
        [self.categoriesTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newCategoryIndex] withAnimation:NSTableViewAnimationSlideRight];
    }
}

#pragma mark - Resizing

- (void)handleResize:(NSNotification *)notification
{
    [self.programsCollectionView.collectionViewLayout invalidateLayout];
    
    CGFloat descriptionWidth = self.programDetailsContainerView.frame.size.width - 431.0;
    if (descriptionWidth > 659.0) {
        descriptionWidth = 659.0;
    }
    
    self.programDetailsDescriptionScrollWidthConstraint.constant = descriptionWidth;
}

#pragma mark - Login Changed

- (void)handleLoginStateChanged:(NSNotification *)notification
{
    if (self.selectedProgram) {
        [self loadDetailsForProgram:self.selectedProgram];
    }
}

#pragma mark - Playing Programs

- (IBAction)playCurrentProgramClicked:(id)sender
{
    [[TVPNetworkManager sharedInstance] catchUpStreamForProgramId:self.selectedProgram.programId
                                                          success:^(NSString *catchUpStreamPath, NSString *drmToken) {
//                                                              NSLog(@"Catch Up Stream: %@", catchUpStreamPath);
//                                                              NSLog(@"Catch Up DRM: %@", drmToken);
                                                          }
                                                          failure:^(NSError *error) {
                                                              
                                                          }];
    AppDelegate *appDelegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    
    [appDelegate playProgram:self.selectedProgram];
}

@end

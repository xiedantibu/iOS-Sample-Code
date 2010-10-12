//
//  XCGalleryView.m
//  EasyGallery
//
//  Created by Hiroshi Hashiguchi on 10/10/07.
//  Copyright 2010 . All rights reserved.
//

#import "XCGalleryView.h"
#import "XCGalleryInnerScrollView.h"

#define DEFAULT_SPACING_WIDTH	40
#define DEFAULT_SPACING_HEIGHT	0
#define DEFAULT_MARGIN_WIDTH	40
#define DEFAULT_MARGIN_HEIGHT	10

enum {
	kIndexOfPreviousScrollView = 0,
	kIndexOfCurrentScrollView,
	kIndexOfNextScrollView,
	kMaxOfScrollView
};

@implementation XCGalleryView

@synthesize currentImageIndex = currentImageIndex_;
@synthesize scrollView = scrollView_;
@synthesize contentOffsetIndex = contentOffsetIndex_;
@synthesize imageScrollViews = imageScrollViews_;
@synthesize delegate = delegate_;
@synthesize showcaseModeEnabled = showcaseModeEnabled_;
@synthesize showcaseMargin = showcaseMargin_;
@synthesize viewSpacing = viewSpacing_;

#pragma mark -
#pragma mark Controle scroll views
- (void)setImageAtIndex:(NSInteger)index toScrollView:(UIScrollView*)scrollView
{
	UIImageView* imageView = [scrollView.subviews objectAtIndex:0];
	if (index < 0 || [self.delegate numberViewsInGallery:self] <= index) {
		imageView.image = nil;
		return;
	}
	
	UIImage* image = [self.delegate galleryImage:self filenameAtIndex:index];
	imageView.image = image;
}


- (void)reloadData
{
	NSInteger numberOfViews = [self.delegate numberViewsInGallery:self];
	if (self.currentImageIndex >= numberOfViews) {
		if (numberOfViews == 0) {
			self.currentImageIndex = 0;
		} else {
			self.currentImageIndex = numberOfViews-1;
		}
		self.contentOffsetIndex = self.currentImageIndex;
	}
	
	for (int index=0; index < kMaxOfScrollView; index++) {
		[self setImageAtIndex:self.currentImageIndex+index-1
				 toScrollView:[self.imageScrollViews objectAtIndex:index]];
	}
}


- (void)setupSpacingAndMarginAndClips
{
	if (self.showcaseModeEnabled) {
		spacing_ = self.viewSpacing;
		spacing_.width = spacing_.width / 2.0;
		margin_ = self.showcaseMargin;
		self.scrollView.clipsToBounds = NO;
	} else {
		spacing_ = self.viewSpacing;
		margin_ = CGSizeZero;
		self.scrollView.clipsToBounds = YES;
	}
}

- (void)setupSubViews
{	
	NSLog(@"self: %@", NSStringFromCGRect(self.frame));
	
	// initialize vars
	self.viewSpacing = CGSizeMake(
								  DEFAULT_SPACING_WIDTH, DEFAULT_SPACING_HEIGHT);
	self.showcaseMargin = CGSizeMake(
									 DEFAULT_MARGIN_WIDTH, DEFAULT_MARGIN_HEIGHT);
	[self setupSpacingAndMarginAndClips];
	
	// setup self view
	//-------------------------
	self.autoresizingMask =
		UIViewAutoresizingFlexibleLeftMargin  |
		UIViewAutoresizingFlexibleWidth       |
		UIViewAutoresizingFlexibleRightMargin |
		UIViewAutoresizingFlexibleTopMargin   |
		UIViewAutoresizingFlexibleHeight      |
		UIViewAutoresizingFlexibleBottomMargin;
	self.clipsToBounds = YES;
	self.backgroundColor = [UIColor blackColor];	// default
	
	
	// setup base scroll view
	//-------------------------
	CGRect baseFrame = self.bounds;
	baseFrame = CGRectInset(baseFrame, margin_.width, margin_.height);
	
	self.scrollView = [[[UIScrollView alloc] initWithFrame:baseFrame] autorelease];
	NSLog(@"scrollView1: %@", NSStringFromCGRect(self.scrollView.frame));
	
	self.scrollView.delegate = self;
	self.scrollView.pagingEnabled = YES;
	self.scrollView.showsHorizontalScrollIndicator = NO;
	self.scrollView.showsVerticalScrollIndicator = NO;
	self.scrollView.scrollsToTop = NO;
	CGRect scrollViewFrame = self.scrollView.frame;
	scrollViewFrame.origin.x -= spacing_.width/2.0;
	scrollViewFrame.size.width += spacing_.width;
	self.scrollView.frame =scrollViewFrame;
	self.scrollView.autoresizingMask =
		UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	
	NSLog(@"scrollView2: %@", NSStringFromCGRect(self.scrollView.frame));

	// DEBUG:
	//self.backgroundColor = [UIColor blueColor];
	//self.scrollView.backgroundColor = [UIColor redColor];
	
	[self addSubview:self.scrollView];
	
	// setup internal scroll views
	//------------------------------
	CGRect innerScrollViewFrame = CGRectZero;
	innerScrollViewFrame.size = baseFrame.size;
	innerScrollViewFrame.origin.x = -1 * innerScrollViewFrame.size.width;
	if (self.showcaseModeEnabled) {
		innerScrollViewFrame.origin.x -= spacing_.width;
	}

	self.imageScrollViews = [NSMutableArray array];
	
	CGRect imageViewFrame = CGRectZero;
	imageViewFrame.size = innerScrollViewFrame.size;
	// DEBUG
	NSLog(@"imageViewFrame: %@", NSStringFromCGRect(imageViewFrame));
	
	for (int i=0; i < kMaxOfScrollView; i++) {
		NSLog(@"innerScrollViewFrame: %@", NSStringFromCGRect(innerScrollViewFrame));
		
		// image view
		//--------------
		UIImageView* imageView =
			[[UIImageView alloc] initWithFrame:imageViewFrame];
		imageView.autoresizingMask =
			UIViewAutoresizingFlexibleLeftMargin  |
			UIViewAutoresizingFlexibleWidth       |
			UIViewAutoresizingFlexibleRightMargin |
			UIViewAutoresizingFlexibleTopMargin   |
			UIViewAutoresizingFlexibleHeight      |
			UIViewAutoresizingFlexibleBottomMargin;

		//		imageView.contentMode = UIViewContentModeScaleAspectFit;

		// scroll view
		//--------------
		innerScrollViewFrame.origin.x += spacing_.width/2.0;	// left space
		
		XCGalleryInnerScrollView* innerScrollView =
			[[XCGalleryInnerScrollView alloc] initWithFrame:innerScrollViewFrame];
		innerScrollView.clipsToBounds = YES;

		innerScrollView.backgroundColor = self.backgroundColor;
		
		// bind & store views
		[innerScrollView addSubview:imageView];
		[self.scrollView addSubview:innerScrollView];
		[self.imageScrollViews addObject:innerScrollView];
		
		// release all
		[imageView release];
		[innerScrollView release];
		
		// adust origin.x
		innerScrollViewFrame.origin.x += innerScrollViewFrame.size.width;
		innerScrollViewFrame.origin.x += spacing_.width/2.0;	// right space
		
	}
	
}	

- (void)layoutSubviews
{
	if (!didSetup_) {
		// initialization for only first time
		[self setupSubViews];
		[self reloadData];
		didSetup_ = YES;
	}

	CGSize newSize;
	if (self.showcaseModeEnabled) {
		newSize = self.scrollView.bounds.size;
		newSize.width -= spacing_.width;
	} else {
		newSize = self.bounds.size;
	}
	CGSize oldSize = previousScrollSize_;

	if (CGSizeEqualToSize(newSize, oldSize)) {
		return;
	}

	[self setupSpacingAndMarginAndClips];

	previousScrollSize_ = newSize;
	CGSize newSizeWithSpace = newSize;
	if (self.showcaseModeEnabled) {
		newSizeWithSpace.width += spacing_.width;
	} else {
		newSizeWithSpace.width += spacing_.width;
	}
	
	// save previous contentSize
	//--
	XCGalleryInnerScrollView* currentScrollView =
		[self.imageScrollViews objectAtIndex:kIndexOfCurrentScrollView];
	CGSize oldContentSize = currentScrollView.contentSize;
	CGPoint oldContentOffset = currentScrollView.contentOffset;
	
	CGFloat zoomScale = currentScrollView.zoomScale;
	
	// calculate ratio (center / size)
	CGPoint oldCenter;
	oldCenter.x = oldContentOffset.x + oldSize.width/2.0;
	oldCenter.y = oldContentOffset.y + oldSize.height/2.0;
	
	CGFloat ratioW = oldCenter.x / oldContentSize.width;
	CGFloat ratioH = oldCenter.y / oldContentSize.height;
	
	
	// set new origin and size to imageScrollViews
	//--
	CGFloat x = (self.contentOffsetIndex-1) * newSizeWithSpace.width;
	for (XCGalleryInnerScrollView* scrollView in self.imageScrollViews) {

		x += spacing_.width/2.0;	// left space
		
		scrollView.frame = CGRectMake(x, 0, newSize.width, newSize.height);
		NSLog(@"scrollView[layouting]: %@", NSStringFromCGRect(scrollView.frame));
		CGSize contentSize;
		if (scrollView == currentScrollView) {
			contentSize.width  = newSize.width  * scrollView.zoomScale;
			contentSize.height = newSize.height * scrollView.zoomScale;
		} else {
			contentSize = newSize;
		}
		scrollView.contentSize = contentSize;
		x += newSize.width;
		x += spacing_.width/2.0;	// right space
	}
	
	
	// adjust current scroll view for zooming
	//--
	if (zoomScale > 1.0) {
		CGSize newContentSize = currentScrollView.contentSize;
		
		CGPoint newCenter;
		newCenter.x = ratioW * newContentSize.width;
		newCenter.y = ratioH * newContentSize.height;
		
		CGPoint newContentOffset;
		newContentOffset.x = newCenter.x - newSize.width /2.0;
		newContentOffset.y = newCenter.y - newSize.height/2.0;
		currentScrollView.contentOffset = newContentOffset;

		/*
		NSLog(@"oldContentSize  : %@", NSStringFromCGSize(oldContentSize));
		NSLog(@"oldContentOffset: %@", NSStringFromCGPoint(oldContentOffset));
		NSLog(@"ratio           : %f, %f", ratioW, ratioH);
		NSLog(@"oldCenter       : %@", NSStringFromCGPoint(oldCenter));
		NSLog(@"newCenter       : %@", NSStringFromCGPoint(newCenter));
		NSLog(@"newContentOffset: %@", NSStringFromCGPoint(newContentOffset));
		NSLog(@"-----");
		 */
	}
	NSLog(@"oldSize         : %@", NSStringFromCGSize(oldSize));
	NSLog(@"newSize         : %@", NSStringFromCGSize(newSize));
	NSLog(@"scrollView.frame: %@", NSStringFromCGRect(self.scrollView.frame));
	
	// adjust content size and offset of base scrollView
	//--
	self.scrollView.contentSize = CGSizeMake(
		[self.delegate numberViewsInGallery:self]*newSizeWithSpace.width,
		newSize.height);
	self.scrollView.contentOffset = CGPointMake(
		self.contentOffsetIndex*newSizeWithSpace.width, 0);
	NSLog(@"newSizeWithSpace:%@", NSStringFromCGSize(newSizeWithSpace));
	NSLog(@"scrollView.contentOffset: %@", NSStringFromCGPoint(self.scrollView.contentOffset));
}


#pragma mark -
#pragma mark Accessors
- (void)setDelegate:(id <XCGalleryViewDelegate>)delegate
{
	delegate_ = delegate;
	[self reloadData];
}


#pragma mark -
#pragma mark Initialization and deallocation

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
		//
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		//
    }
    return self;
}

/*
 - (void)awakeFromNib
 {
 [self setupSubViews];
 }
 */

- (void)dealloc {
	self.scrollView = nil;
	self.imageScrollViews = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Control Scroll

-(void)setupPreviousImage
{
	XCGalleryInnerScrollView* previousScrollView =
		[self.imageScrollViews objectAtIndex:kIndexOfPreviousScrollView];
	XCGalleryInnerScrollView* currentScrollView =
		[self.imageScrollViews objectAtIndex:kIndexOfCurrentScrollView];
	XCGalleryInnerScrollView* nextScrollView =
		[self.imageScrollViews objectAtIndex:kIndexOfNextScrollView];
	
	[self.imageScrollViews removeAllObjects];
	[self.imageScrollViews addObject:nextScrollView];
	[self.imageScrollViews addObject:previousScrollView];
	[self.imageScrollViews addObject:currentScrollView];

	CGRect frame = previousScrollView.frame;
	frame.origin.x -= frame.size.width + spacing_.width;
	nextScrollView.frame = frame;
	[self setImageAtIndex:self.currentImageIndex-1 toScrollView:nextScrollView];
}

-(void)setupNextImage
{
	XCGalleryInnerScrollView* previousScrollView =
		[self.imageScrollViews objectAtIndex:kIndexOfPreviousScrollView];
	XCGalleryInnerScrollView* currentScrollView =
		[self.imageScrollViews objectAtIndex:kIndexOfCurrentScrollView];
	XCGalleryInnerScrollView* nextScrollView =
		[self.imageScrollViews objectAtIndex:kIndexOfNextScrollView];
	
	[self.imageScrollViews removeAllObjects];
	[self.imageScrollViews addObject:currentScrollView];
	[self.imageScrollViews addObject:nextScrollView];
	[self.imageScrollViews addObject:previousScrollView];

	CGRect frame = nextScrollView.frame;
	frame.origin.x += frame.size.width + spacing_.width;
	previousScrollView.frame = frame;
	[self setImageAtIndex:self.currentImageIndex+1 toScrollView:previousScrollView];
}


#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGFloat position = scrollView.contentOffset.x / scrollView.bounds.size.width;
	CGFloat delta = position - (CGFloat)self.currentImageIndex;
	
	if (fabs(delta) >= 1.0f) {
		XCGalleryInnerScrollView* currentScrollView =
		[self.imageScrollViews objectAtIndex:kIndexOfCurrentScrollView];
		currentScrollView.zoomScale = 1.0;
		currentScrollView.contentOffset = CGPointZero;
		
		//		NSLog(@"%f (%d=>%d)", delta, self.currentImageIndex, index);
		
		if (delta > 0) {
			// the current page moved to right
			self.currentImageIndex = self.currentImageIndex+1;
			self.contentOffsetIndex = self.contentOffsetIndex+1;
			[self setupNextImage];
			
		} else {
			// the current page moved to left
			self.currentImageIndex = self.currentImageIndex-1;
			self.contentOffsetIndex = self.contentOffsetIndex-1;
			[self setupPreviousImage];
		}
		
	}
	
}


@end

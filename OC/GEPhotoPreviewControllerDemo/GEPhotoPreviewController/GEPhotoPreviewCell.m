//
//  GEPhotoBrowserCell.m
//  ExcellentLearning
//
//  Created by hjp on 16/11/25.
//  Copyright © 2016年 西安恒谦教育科技股份有限公司. All rights reserved.
//

#import "GEPhotoPreviewCell.h"
#import "GEPreviewInnerObject.h"

#import "UIImage+GESDImageCache.h"
#import "UIImageView+GEWebCache.h"
#import "NSString+GESDCache.h"
#import "UIScreen+GEAdd.h"
#import "UIView+GEAdd.h"

#import <Masonry.h>

NSString *const photoBrowserCellId = @"PhotoBrowserCellID";

@interface GEPhotoPreviewCell ()<UIScrollViewDelegate,UIGestureRecognizerDelegate>


//@property (weak, nonatomic) UIActivityIndicatorView *activityView;
/** activity*/
//@property (nonatomic , weak) UIActivityIndicatorView *activity;

/** swipe手势*/
@property (nonatomic , weak) UISwipeGestureRecognizer *swipeGes;
/** pan手势*/
@property (nonatomic , weak) UIPanGestureRecognizer *panGes;

@end
@implementation GEPhotoPreviewCell


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    

//    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//    activityView.frame = CGRectMake([UIScreen screenWidth]/2 - 16, [UIScreen screenHeight]/2 - 16, 32, 32);
//    _activityView = activityView;
//
//    activityView.hidesWhenStopped = YES;
//    [self.imageScrollView addSubview:activityView];

    
    self.imageScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    //设置最小伸缩比例
    self.imageScrollView.delegate = self;
  
    

    // 手势
    UITapGestureRecognizer *tapOneGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOne:)];
    [self.contentView addGestureRecognizer:tapOneGesture];
    
    UITapGestureRecognizer *tapTwoGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTwo:)];
    tapTwoGesture.numberOfTapsRequired = 2;
    [self.contentView addGestureRecognizer:tapTwoGesture];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.contentView addGestureRecognizer:longPress];
    
    [tapOneGesture requireGestureRecognizerToFail:tapTwoGesture];

 
    UISwipeGestureRecognizer *swipeGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    swipeGes.direction = UISwipeGestureRecognizerDirectionDown|UISwipeGestureRecognizerDirectionUp;
    swipeGes.delegate = self;
    [self.imageView addGestureRecognizer:swipeGes];

    UIPanGestureRecognizer *panGes =  [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    panGes.delegate = self;
    [self.imageView addGestureRecognizer:panGes];
    
    
    self.swipeGes = swipeGes;
    self.panGes = panGes;
    

}

- (void)setTranslation:(CGPoint)translation
{
    if (translation.x == _translation.x && translation.y > _translation.y ) {
        _pullDown = YES;
    }else{
        _pullDown = NO;
    }
    
    _translation = translation;
}

#pragma mark - Data
- (void)setPhotoObject:(GEPreviewInnerObject *)photoObject
{
    _photoObject = photoObject;
    
  
    self.imageScrollView.zoomScale = 1.0;

    [photoObject.orignalUrl ge_imageExist:^(BOOL inCache) {
        
        if (!inCache ) {
             self.imageView.contentMode = UIViewContentModeCenter;
        }
        
        
        //    [self.activityView stopAnimating];
        
        switch (photoObject.photoType) {
            case GEPreviewInnerObjectTypeNet:
            {
                __weak typeof(self) weakSelf = self;
                [self.imageView ge_setOrignalImageViewWithThumbURLString:photoObject.thumbnailUrl orignalURLString:photoObject.orignalUrl placeholder:photoObject.praceholder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    
                    weakSelf.imageView.contentMode = UIViewContentModeScaleAspectFit;
                    
                }];
                
            }
                break;
            case GEPreviewInnerObjectTypeLocal:
            {
                self.imageView.image = [[UIImage alloc]initWithContentsOfFile:photoObject.origalLocalPath];
                self.imageView.contentMode = UIViewContentModeScaleAspectFit;
            }
                break;
                
                
                
            default:
                break;
        }
        
        //    self.imageScrollView.zoomScale = photoObject.zoomScale;
    }];
  

    
}



#pragma mark -  UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    self.photoObject.zoomScale = scale;
}



#pragma mark - Event
- (void)tapOne:(UITapGestureRecognizer *)sender{
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        
        if ([self.delegate respondsToSelector:@selector(photoPreviewCell:triggerGesture:)]) {
            
            [self.delegate photoPreviewCell:self triggerGesture:GEPhotoPreviewCellGestureTapOne];
           
        }
    }
}
- (void)tapTwo:(UITapGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        
        if ([self.delegate respondsToSelector:@selector(photoPreviewCell:triggerGesture:)]) {
            
            BOOL result = [self.delegate photoPreviewCell:self triggerGesture:GEPhotoPreviewCellGestureTapTwo];

            if (result) {
                
                if (self.imageScrollView.zoomScale == self.imageScrollView.maximumZoomScale) {
                    
                    [self zoomImageView:self.imageScrollView.minimumZoomScale];
                }else{
                    [self zoomImageView:self.imageScrollView.maximumZoomScale];

                }
            }
        }
    }
}
- (void)longPress:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(photoPreviewCell:triggerGesture:)]) {
            
            [self.delegate photoPreviewCell:self triggerGesture:GEPhotoPreviewCellGestureLongPress];
        }
    }
}

- (void)swipe:(UISwipeGestureRecognizer *)sender {
    
    switch (sender.state ) {
//        case UIGestureRecognizerStateBegan: // 不触发
//        {
//            NSLog(@"swipeBegin");
//        }
//            break;
        case UIGestureRecognizerStateEnded:
        {
            NSLog(@"swipeEnd");
            self.panGes.enabled = NO;

            if ([self.delegate respondsToSelector:@selector(photoPreviewCell:swipeGesture:)]) {
                [self.delegate photoPreviewCell:self swipeGesture:sender];
            }
        }
            break;
        default:
            break;
    }

    
   
}

- (void)pan:(UIPanGestureRecognizer *)sender {
    
    
    switch (sender.state ) {
        case UIGestureRecognizerStateChanged:
        {
            NSLog(@"panChange");

            self.swipeGes.enabled = NO;
            

        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            NSLog(@"panEnd");

            self.swipeGes.enabled = YES;

        }
            break;
        default:
            break;
    }
    
    if ([self.delegate respondsToSelector:@selector(photoPreviewCell:panGesture:)]) {
        [self.delegate photoPreviewCell:self panGesture:sender];
    }

    
}

- (void)zoomImageView:(CGFloat)scale
{
    [self.imageScrollView setZoomScale:scale animated:YES];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        
        UIPanGestureRecognizer *panGes = (UIPanGestureRecognizer *)gestureRecognizer;
        
        CGPoint point = [panGes translationInView:self.imageView];
        if (point.x != 0) {
            return NO;
        }
        
    }
    
    return  YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Public
+ (CGRect)getBigImageRectWithImage:(GEPreviewInnerObject *)photoObject originalImageRect:(CGRect)origImageRect thumImageYMargin:(CGFloat)yMargin
{

    
    BOOL hasBigImage = NO;
    
    UIImage *image = [self getImageByPhotoObject:photoObject hasBigImage:&hasBigImage];
    
    CGRect imageRect = CGRectZero;
    if (hasBigImage) {
        imageRect = origImageRect;

    }else{
        imageRect.origin.x = ([UIScreen screenWidth] - image.size.width ) * .5;
        imageRect.origin.y =  yMargin + ([UIScreen screenHeight] - yMargin - image.size.height ) * .5;
        imageRect.size = image.size;
    }

    
    return imageRect;
}

+ (UIImageView *)imageViewForPhotoBrowserAnimationPresent:(GEPreviewInnerObject *)photoObject
{
    
    
    BOOL hasBigImage = NO;
    
    UIImage *image = [self getImageByPhotoObject:photoObject hasBigImage:&hasBigImage];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = hasBigImage? UIViewContentModeScaleAspectFit:UIViewContentModeCenter;
    imageView.clipsToBounds = YES;
    
    return imageView;
}



+ (UIImage *)getImageByPhotoObject:(GEPreviewInnerObject *)photoObject hasBigImage:(BOOL *)hasBigImage
{
    
    UIImage *image = nil;
    switch (photoObject.photoType) {
        case GEPreviewInnerObjectTypeNet:
        {
            image = [UIImage ge_getSDCacheDiskImageByUrlString:photoObject.orignalUrl];
            *hasBigImage = image?YES:NO;
            image = image?:[UIImage ge_getSDCacheDiskImageByUrlString:photoObject.thumbnailUrl];
            image = image?:[UIImage imageNamed:photoObject.praceholder];
            
        }
            break;
        case GEPreviewInnerObjectTypeLocal:
        {
            image = [[UIImage alloc]initWithContentsOfFile:photoObject.origalLocalPath];
            *hasBigImage = image? YES:NO;
            image = image?:[[UIImage alloc] initWithContentsOfFile:photoObject.thumbLocalPath];
            image = image?:[UIImage imageNamed:photoObject.thumbLocalPath];
            image = image?:[UIImage imageNamed:photoObject.praceholder];
            
        }
            break;
            
        default:
            break;
    }
    
    return image;
}




@end

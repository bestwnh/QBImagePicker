//
//  QBImagePickerController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBImagePickerController.h"

// ViewControllers
#import "QBAlbumsViewController.h"


@interface QBImagePickerController ()

@property (nonatomic, strong) UINavigationController *albumsNavigationController;

@property (nonatomic, strong) NSBundle *assetBundle;

@property (nonatomic, strong, readonly) NSMutableOrderedSet *storedSelectedAssets;

@end

@implementation QBImagePickerController

+ (BOOL) usingPhotosLibrary {

    return (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0);
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        if ([QBImagePickerController usingPhotosLibrary] == NO) {
    
            self.assetsLibrary = [ALAssetsLibrary new];
        }
        
        self.collectionSubtypes = @[@(QBImagePickerCollectionSubtypeAll)];
        
        self.minimumNumberOfSelection = 1;
        self.numberOfColumnsInPortrait = 4;
        self.numberOfColumnsInLandscape = 7;
        
        _selectedAssets = [NSMutableOrderedSet orderedSet];
        _storedSelectedAssets = [NSMutableOrderedSet orderedSet];
        
        // Get asset bundle
        self.assetBundle = [NSBundle bundleForClass:[self class]];
        NSString *bundlePath = [self.assetBundle pathForResource:@"QBImagePicker" ofType:@"bundle"];
        if (bundlePath) {
            self.assetBundle = [NSBundle bundleWithPath:bundlePath];
        }
        
        [self setUpAlbumsViewController];
        
        // Set instance
        QBAlbumsViewController *albumsViewController = (QBAlbumsViewController *)self.albumsNavigationController.topViewController;
        albumsViewController.imagePickerController = self;
    }
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.storedSelectedAssets removeAllObjects];
    [self.storedSelectedAssets addObjectsFromArray:self.selectedAssets.array];
}

- (void)cancelSelectedAssetsChange
{
    [self.selectedAssets removeAllObjects];
    [self.selectedAssets addObjectsFromArray:self.storedSelectedAssets.array];
}

- (void)setUpAlbumsViewController
{
    // Add QBAlbumsViewController as a child
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"QBImagePicker" bundle:self.assetBundle];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"QBAlbumsNavigationController"];
    
    [self addChildViewController:navigationController];
    
    navigationController.view.frame = self.view.bounds;
    [self.view addSubview:navigationController.view];
    
    [navigationController didMoveToParentViewController:self];
    
    self.albumsNavigationController = navigationController;
}

- (void)fetchSelectedAssetThumbnailsWithSize:(CGSize)size completion:(void (^)(NSArray *))completion
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSMutableOrderedSet *selectedAssets = self.selectedAssets;
    
    void (^checkNumberOfAssets)(void) = ^{
        if (array.count == selectedAssets.count) {
            if (completion) {
                completion([array copy]);
            }
        }
    };
    
    if ([QBImagePickerController usingPhotosLibrary]) {
        CGFloat scale = [[UIScreen mainScreen] scale];
        for (PHAsset *asset in self.selectedAssets) {
            [[PHCachingImageManager defaultManager] requestImageForAsset:asset
                                                              targetSize:CGSizeMake(size.width * scale, size.height * scale)
                                                             contentMode:PHImageContentModeAspectFit
                                                                 options:nil
                                                           resultHandler:^(UIImage *result, NSDictionary *info) {
                                                               [array addObject:result];
                                                               // Check if the loading finished
                                                               checkNumberOfAssets();
                                                               
                                                           }];
        }
    } else {
        for (ALAsset *asset in self.selectedAssets) {
            [array addObject:[UIImage imageWithCGImage:asset.thumbnail]];
        }
        completion([array copy]);
    }
    
}

@end

//
//  GoBoardView.h
//  Mingo
//
//  Created by Horace Ho on 2015/05/18.
//  Copyright (c) 2015 Horace Ho. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GoBoardView : UIView

@property (assign, nonatomic) BOOL isLabelOn;

- (CGPoint)pointToCoor:(CGPoint)point;

@end

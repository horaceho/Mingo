//
//  GoBoardView.m
//  Mingo
//
//  Created by Horace Ho on 2015/05/18.
//  Copyright (c) 2015 Horace Ho. All rights reserved.
//

#import "michi-ios.h"
#import "UIImage+PDF.h"
#import "GoBoardView.h"

@interface GoBoardView ()

@property (strong, nonatomic) Michi *game;
@property (strong, nonatomic) UIImage *boardImage;
@property (strong, nonatomic) UIImage *whiteImage;
@property (strong, nonatomic) UIImage *blackImage;

@property (strong, nonatomic) UIColor *gridLineColor;

@end

@implementation GoBoardView

- (Michi *)game {
    if (_game == nil) {
        _game = Michi.one;
    }
    return _game;
}

- (UIImage *)whiteImage {
    if (_whiteImage == nil) {
        CGSize size = self.gridSize;
        _whiteImage = [UIImage imageWithPDFNamed:@"WhiteStone.pdf" atWidth:(size.width-2)];
    }
    return _whiteImage;
}

- (UIImage *)blackImage {
    if (_blackImage == nil) {
        CGSize size = self.gridSize;
        _blackImage = [UIImage imageWithPDFNamed:@"BlackStone.pdf" atWidth:(size.width-2)];
    }
    return _blackImage;
}

- (UIColor *)gridLineColor {
    if (_gridLineColor == nil) {
        _gridLineColor = UIColor.darkGrayColor;
    }
    return _gridLineColor;
}

- (CGPoint)pointToCoor:(CGPoint)point
{
    if (point.x > self.boardRect.origin.x) point.x -= self.boardRect.origin.x;
    if (point.y > self.boardRect.origin.y) point.y -= self.boardRect.origin.y;

 // CGSize gridHalf = CGSizeMake(self.gridSize.width/2.0, self.gridSize.height/2.0);

    NSInteger x = point.x / self.gridSize.width;
    NSInteger y = point.y / self.gridSize.height;

    if (x >= self.game.size) x = self.game.size - 1;
    if (y >= self.game.size) y = self.game.size - 1;

    CGPoint coor = CGPointMake(x, y);
    return coor;
}

- (CGSize)insetSize {
    CGFloat size = self.isLabelOn ? 8.0 : 0.0;
    return CGSizeMake(size, size);
}

- (CGSize)gridSize {
    CGFloat shortSide = (self.frame.size.width > self.frame.size.height) ? self.frame.size.height : self.frame.size.width;
    NSInteger gridWidth = (shortSide - (self.insetSize.width * 2.0))  / self.game.size;
    NSInteger gridHeight = gridWidth + 1;
    CGSize size = CGSizeMake(gridWidth, gridHeight);
    return size;
}

- (CGSize)boardSize {
    CGSize size = CGSizeMake(self.gridSize.width * self.game.size, self.gridSize.height * self.game.size);
    return size;
}

- (CGRect)boardRect {
    NSInteger marginX = (self.frame.size.width  - self.boardSize.width)  / 2.0;
    NSInteger marginY = (self.frame.size.height - self.boardSize.height) / 2.0;
    CGRect rect = CGRectMake(marginX, marginY, self.boardSize.width, self.boardSize.height);
    return rect;
}

- (void)drawStone:(GoStone)stone point:(GoPoint)point {
    if (stone != kWhite && stone != kBlack) return;

    UIImage *image;
    if (stone == kWhite) image = self.whiteImage;
    if (stone == kBlack) image = self.blackImage;

    if (image == nil) return;

    BOOL shadowOn = YES;
    CGFloat shadowOffset = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 5.0 : 2.0;
    CGFloat shadowBlur   = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 5.0 : 5.0;
    CGPoint drawPoint;
    NSInteger offsetX = self.boardRect.origin.x;
    NSInteger offsetY = self.boardRect.origin.y;
    drawPoint.x = offsetX + point.col * self.gridSize.width;
    drawPoint.y = offsetY + point.row * self.gridSize.height;
    if (shadowOn) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShadow(context, CGSizeMake(shadowOffset, shadowOffset), shadowBlur);
    }
    [image drawAtPoint:drawPoint];
}

- (void)drawStones {
    for (NSInteger row = 0; row < self.game.size; row++) {
        for (NSInteger col = 0; col < self.game.size; col++) {
            GoPoint point;
            point.row = row;
            point.col = col;
            GoStone stone = [self.game stoneAt:point];
            [self drawStone:stone point:point];
        }
    }
}

- (void)drawStar:(CGRect)rect col:(NSInteger)col row:(NSInteger)row {
    NSInteger offsetX = self.boardRect.origin.x + self.gridSize.width  / 2.0;
    NSInteger offsetY = self.boardRect.origin.y + self.gridSize.height / 2.0;

    CGFloat starSize = 4.0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        starSize = 6.0;
    }
    CGFloat x = offsetX + (col * self.gridSize.width)  - (starSize / 2);
    CGFloat y = offsetY + (row * self.gridSize.height) - (starSize / 2);
    CGRect starRect = CGRectMake(x, y, starSize, starSize);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.gridLineColor.CGColor);
    CGContextFillEllipseInRect(context, starRect);
}

- (void)drawString:(NSString*)s withFont:(UIFont*)font inRect:(CGRect) contextRect {
    // Make a copy of the default paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    // Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    // Set text alignment
    paragraphStyle.alignment = NSTextAlignmentCenter;

    NSDictionary *attributes = @{ NSFontAttributeName:font,
                                  NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                  NSParagraphStyleAttributeName:paragraphStyle };

    CGSize size = [s sizeWithAttributes:attributes];

    CGRect textRect = CGRectMake(contextRect.origin.x + floorf((contextRect.size.width - size.width) / 2.0),
                                 contextRect.origin.y + floorf((contextRect.size.height - size.height) / 2.0),
                                 size.width,
                                 size.height);

    [s drawInRect:textRect withAttributes:attributes];
}

- (void)drawBoard {
 // NSLog(@"%s boardRect: %@", __func__, NSStringFromCGRect(self.boardRect));
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, UIColor.redColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokeRect(context, self.boardRect);

    CGFloat lineWidth = 1.0;
    CGFloat frameWidth = 2.0;

    NSInteger boardWidth  = self.game.size;
    NSInteger boardHeight = self.game.size;

    NSInteger gridWidth  = self.gridSize.width;
    NSInteger gridHeight = self.gridSize.height;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        frameWidth = 3.0;
    }

    NSInteger offsetX = self.boardRect.origin.x + self.gridSize.width  / 2.0;
    NSInteger offsetY = self.boardRect.origin.y + self.gridSize.height / 2.0;
    CGSize marginSize = CGSizeMake(offsetX, offsetY);

    // Vertical lines
    for (NSInteger n = 1; n < boardWidth-1; n++) {
        CGContextSetStrokeColorWithColor(context, self.gridLineColor.CGColor);
        CGContextSetLineWidth(context, lineWidth);
        CGFloat fromX = marginSize.width + (n * gridWidth);
        CGFloat fromY = marginSize.height;
        CGFloat toX = marginSize.width  + (gridWidth * n);
        CGFloat toY = marginSize.height + (gridHeight * (boardHeight-1));
        CGContextMoveToPoint(context, fromX, fromY);
        CGContextAddLineToPoint(context, toX, toY);
        CGContextStrokePath(context);
    }

    // Horizontal lines
    for (NSInteger n = 1; n < boardHeight-1; n++) {
        CGContextSetStrokeColorWithColor(context, self.gridLineColor.CGColor);
        CGContextSetLineWidth(context, lineWidth);
        CGFloat fromX = marginSize.width;
        CGFloat fromY = marginSize.height + (n * gridHeight);
        CGFloat toX = marginSize.width  + (gridWidth * (boardWidth-1));
        CGFloat toY = marginSize.height + (gridHeight * n);
        CGContextMoveToPoint(context, fromX, fromY);
        CGContextAddLineToPoint(context, toX, toY);
        CGContextStrokePath(context);
    }

    // Frame
    CGRect boardRect = CGRectMake(marginSize.width, marginSize.height, (boardWidth-1)*gridWidth, (boardHeight-1)*gridHeight);
    CGContextSetStrokeColorWithColor(context, self.gridLineColor.CGColor);
    CGContextSetLineWidth(context, frameWidth);
    CGContextStrokeRect(context, boardRect);

    // Label
    if (self.isLabelOn) {
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetLineWidth(context, 1.0);

        CGFloat fontSize = 12.0;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            fontSize = 18.0;
        }
        UIFont *font = [UIFont fontWithName:@"Thonburi" size:fontSize];
        for (NSInteger n = 0; n < boardHeight; n++) {
            CGFloat fromX = 0;
            CGFloat fromY = marginSize.height + (n * gridHeight);
            CGRect drawRect = CGRectMake(fromX, fromY-(gridHeight/2.0), (gridWidth/2.0), gridHeight);
            NSString *string = [self.game stringFromRow:n];
            [self drawString:string withFont:font inRect:drawRect];
         // CGContextSetStrokeColorWithColor(context, UIColor.redColor.CGColor);
         // CGContextStrokeRect(context, drawRect);
        }
        for (NSInteger n = 0; n < boardHeight; n++) {
            CGFloat fromX = marginSize.width + self.gridSize.width * n - (self.gridSize.width / 2.0);
            CGFloat fromY = marginSize.height + self.gridSize.height * (self.game.size - 1);
            CGRect drawRect = CGRectMake(fromX, fromY, gridWidth, gridHeight);
            NSString *string = [self.game stringFromCol:n];
            [self drawString:string withFont:font inRect:drawRect];
         // CGContextSetStrokeColorWithColor(context, UIColor.greenColor.CGColor);
         // CGContextStrokeRect(context, drawRect);
        }
    }

    // Stars
    if (boardWidth > 3 && boardHeight > 3) {
        [self drawStar:self.boardRect col:3 row:3]; // upper left
        if (boardWidth >= 9) {
            [self drawStar:self.boardRect col:boardWidth-4 row:3]; // upper right
            if (boardWidth >= 13 && (boardWidth&1)) {
                NSInteger midBoard = boardWidth / 2;
                [self drawStar:self.boardRect col:midBoard row:3]; // uppper middle
            }
        }
        if (boardHeight >= 9) {
            [self drawStar:self.boardRect col:3 row:boardHeight-4]; // lower left
            if (boardHeight >= 13 && (boardHeight&1)) {
                NSInteger midBoard = boardHeight / 2;
                [self drawStar:self.boardRect col:3 row:midBoard]; // middle left
            }
        }
        if (boardWidth >= 9 && boardHeight >= 9) {
            [self drawStar:self.boardRect col:boardWidth-4 row:boardHeight-4]; // lower right
            if (boardWidth >= 13 && (boardWidth&1)) {
                NSInteger midBoard = boardWidth / 2;
                [self drawStar:self.boardRect col:midBoard row:boardHeight-4]; // middle right
            }
            if (boardHeight >= 13 && (boardHeight&1)) {
                NSInteger midBoard = boardHeight / 2;
                [self drawStar:self.boardRect col:boardWidth-4 row:midBoard]; // lower middle
            }
            if (boardHeight >= 13 && boardHeight >= 13 && (boardWidth&1) && (boardHeight&1)) {
                NSInteger midWidth = boardWidth / 2;
                NSInteger midHeight = boardHeight / 2;
                [self drawStar:self.boardRect col:midWidth row:midHeight]; // middle
            }
        }
    }
}

- (void)drawAscii {
    for (NSInteger row = 0; row < self.game.size; row++) {
        for (NSInteger col = 0; col < self.game.size; col++) {
            GoPoint point;
            point.row = row;
            point.col = col;
            GoStone stone = [self.game stoneAt:point];
            if (stone == kBlack) {
                printf("X ");
            } else if (stone == kWhite) {
                printf("O ");
            } else {
                printf(". ");
            }
        }
        printf("\n");
    }
}

- (void)drawAll {
    [self drawAscii];
    [self drawBoard];
    [self drawStones];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [self drawAll];
}

- (void)updateConstraints {
    [super updateConstraints];
 // NSLog(@"%s view: %@", __func__, NSStringFromCGRect(self.frame));
}

- (void)layoutSubviews {
    [super layoutSubviews];
 // NSLog(@"%s view: %@", __func__, NSStringFromCGRect(self.frame));
}

@end

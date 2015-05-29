//
//  ViewController.m
//  Mingo
//
//  Created by Horace Ho on 2015/05/15.
//  Copyright (c) 2015 Horace Ho. All rights reserved.
//

#import "michi-ios.h"
#import "GoBoardView.h"
#import "FontAwesomeKit.h"
#import "ViewController.h"

@interface ViewController () <UIActionSheetDelegate>

@property (strong, nonatomic) IBOutlet GoBoardView *boardView;
@property (strong, nonatomic) IBOutlet UIButton *hintButton;
@property (strong, nonatomic) IBOutlet UIButton *undoButton;
@property (strong, nonatomic) IBOutlet UIButton *menuButton;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (assign, nonatomic) NSUInteger thinkingTimeOfGame;
@property (assign, nonatomic) NSUInteger thinkingTimeOfMove;

@property (strong, nonatomic) NSMutableAttributedString *hintMas;
@property (strong, nonatomic) NSMutableAttributedString *undoMas;
@property (strong, nonatomic) NSMutableAttributedString *menuMas;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"Michi version %@", Michi.one.version);

    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.boardView addGestureRecognizer:singleFingerTap];

    self.boardView.isLabelOn = NO;

    UIImage *boardImage = [UIImage imageNamed:@"Board.gif"];
    UIColor *color = [UIColor colorWithPatternImage:boardImage];
    self.boardView.backgroundColor = color;

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(heartBeat:)
                                   userInfo:nil
                                    repeats:YES];

    self.thinkingTimeOfGame = 0;
    self.thinkingTimeOfMove = 0;

    [self.hintButton setAttributedTitle:self.hintMas forState:UIControlStateNormal];
    [self.undoButton setAttributedTitle:self.undoMas forState:UIControlStateNormal];
    [self.menuButton setAttributedTitle:self.menuMas forState:UIControlStateNormal];

    self.hintButton.hidden = YES;
    self.undoButton.hidden = YES;
    self.menuButton.hidden = YES;
    self.timeLabel.hidden  = YES;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:recognizer.view];
    CGPoint coor = [self.boardView pointToCoor:location];
    NSString *string = [Michi.one stringFromPoint:coor];
    [self log:string];

    GoPoint point;
    point.col = coor.x;
    point.row = coor.y;
    [Michi.one playMove:point];

    [self refreshAll];
}

- (NSOperationQueue *)operationQueue {
    if (_operationQueue == nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.hintButton.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [Michi.one setup];
    self.hintButton.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)log:(NSString *)message {
}

- (void)testMichi {
    [Michi.one autoMove];
    [Michi.one autoMove];
    [Michi.one autoMove];
}

- (void)computerGo {
    self.thinkingTimeOfMove = 0;
    [Michi.one autoMove];
    self.thinkingTimeOfGame += self.thinkingTimeOfMove;

    [self performSelectorOnMainThread:@selector(refreshAll) withObject:nil waitUntilDone:NO];
}

- (BOOL)computerThinking {
    return (self.operationQueue.operationCount > 0) ? YES : NO;
}

- (IBAction)hintButtonClicked:(id)sender {
    if (self.computerThinking == NO) {
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(computerGo) object:nil];
        [self.operationQueue addOperation:operation];
    }
    [self refreshAll];
}

- (IBAction)undoButtonClicked:(id)sender {
    [Michi.one undoMove];
    [self refreshAll];
}

- (IBAction)menuButtonClicked:(UIButton *)button {
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    NSString *resetTitle = NSLocalizedString(@"Reset", nil);
    NSString *loadTitle = NSLocalizedString(@"Load", nil);
    NSString *saveTitle = NSLocalizedString(@"Save", nil);
    NSString *helpTitle = NSLocalizedString(@"Help", nil);
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:cancelTitle
                                               destructiveButtonTitle:resetTitle
                                                    otherButtonTitles:loadTitle, saveTitle, helpTitle, nil];
    [actionSheet showFromRect:button.frame inView:self.view animated:YES];
    [self refreshButtons];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // reset
        if (!self.computerThinking) {
            [Michi.one reset];
            [self refreshAll];
        }
    } else if  (buttonIndex == 1) { // Load
        if (!self.computerThinking) {
            [Michi.one autoLoadGame];
            [self refreshAll];
        }
    } else if  (buttonIndex == 2) { // Save
        if (!self.computerThinking) {
            [Michi.one autoSaveGame];
            [self refreshAll];
        }
    } else if  (buttonIndex == 3) { // Help
        ;
    }
    [self refreshButtons];
}

- (void)refreshButtons {
    if (self.computerThinking) {
        self.thinkingTimeOfMove++;
        self.timeLabel.text = @(self.thinkingTimeOfMove).stringValue;

        self.hintButton.hidden = YES;
        self.undoButton.hidden = YES;
        self.menuButton.hidden = YES;
        self.timeLabel.hidden  = NO;
    } else {
        self.hintButton.hidden = NO;
        self.undoButton.hidden = Michi.one.isUndoOK ? NO : YES;
        self.menuButton.hidden = NO;
        self.timeLabel.hidden  = YES;
    }
}

- (void)refreshAll {
    [self.boardView setNeedsDisplay];
    [self refreshButtons];
}

- (void)heartBeat:(id)sender {
    [self refreshButtons];
}

- (NSMutableAttributedString *)hintMas {
    if (_hintMas == nil) {
        CGFloat fontSize = self.hintButton.titleLabel.font.pointSize;
        FAKFontAwesome *hintIcon = [FAKFontAwesome magicIconWithSize:fontSize];
        _hintMas = [[hintIcon attributedString] mutableCopy];
    }
    return _hintMas;
}

- (NSMutableAttributedString *)undoMas {
    if (_undoMas == nil) {
        CGFloat fontSize = self.undoButton.titleLabel.font.pointSize;
        FAKFontAwesome *undoIcon = [FAKFontAwesome undoIconWithSize:fontSize];
        _undoMas = [[undoIcon attributedString] mutableCopy];
    }
    return _undoMas;
}

- (NSMutableAttributedString *)menuMas {
    if (_menuMas == nil) {
        CGFloat fontSize = self.menuButton.titleLabel.font.pointSize;
        FAKFontAwesome *menuIcon = [FAKFontAwesome barsIconWithSize:fontSize];
        _menuMas = [[menuIcon attributedString] mutableCopy];
    }
    return _menuMas;
}

@end

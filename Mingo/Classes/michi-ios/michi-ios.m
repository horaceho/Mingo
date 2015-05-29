#import "michi.h"
#import "michi-ios.h"

static TreeNode *tree;
static Position *pos = nil, curr_pos, last_pos;
static int *owner_map;

char* empty_position(Position *pos);
TreeNode* new_tree_node(Position *pos);
void free_tree(TreeNode *tree);
Point tree_search(TreeNode *tree, int n, int owner_map[], int disp);

@interface Michi()

@end

@implementation Michi

+ (instancetype)one
{
    static dispatch_once_t once;
    static Michi *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[Michi alloc] init];

        flog = stdout;
        mark1 = calloc(1, sizeof(Mark));
        mark2 = calloc(1, sizeof(Mark));
        make_pat3set();
        already_suggested = calloc(1, sizeof(Mark));
        pos = &curr_pos;
        empty_position(pos);
        last_pos = curr_pos;
        tree = new_tree_node(pos);
        owner_map = calloc(BOARDSIZE, sizeof(int));
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.version = @"1.0";
    }
    return self;
}

- (void)setup {
    NSString *probPath = [[NSBundle mainBundle] pathForResource:@"patterns" ofType:@"prob"];
    NSString *spatPath = [[NSBundle mainBundle] pathForResource:@"patterns" ofType:@"spat"];
    const char *probFilename = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:probPath];
    const char *spatFilename = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:spatPath];
    init_large_patterns(probFilename, spatFilename);
}

- (NSInteger)size {
    return N;
}

- (BOOL)playMove:(GoPoint)point {
    NSLog(@"%s col: %ld row: %ld", __func__, (long)point.col, (long)point.row);
    BOOL ok = NO;
    NSInteger offset = (point.row+1) * (self.size+1) + (point.col+1);
    if (pos->color[offset] == EMPTY) {
        last_pos = curr_pos;
        play_move(pos, (Point)offset);
    }
    return ok;
}

- (GoStone)whosTurn {
    return ((pos->n)%2) ? kWhite : kBlack;
}

- (GoStone)stoneAt:(GoPoint)point {
    GoStone stone = kEmpty;
    NSInteger offset = (point.row+1) * (self.size+1) + (point.col+1);
    if (pos->color[offset] == WHITE) {
        stone = kWhite;
    } else if (pos->color[offset] == BLACK) {
        stone = kBlack;
    }
    return stone;
}

- (BOOL)isUndoOK {
    return (curr_pos.n > last_pos.n) ? YES : NO;
}

- (void)autoMove {
    Point point = [self hint];
    [self play:point];
}

- (void)undoMove {
    if (curr_pos.n > last_pos.n) {
        free_tree(tree);
        curr_pos = last_pos;
        tree = new_tree_node(pos);
    }
}

- (Point)hint {
    Point point;
    if (pos->last == PASS_MOVE && pos->n>2) {
         point = PASS_MOVE;
    }
    else {
        free_tree(tree);
        tree = new_tree_node(pos);
        point = tree_search(tree, N_SIMS, owner_map, 0);
    }

    char buffer[5];
    NSLog(@"%s %s", __func__, str_coord(point, buffer));

    return point;
}

- (void)play:(Point)point {
    if (point == PASS_MOVE) {
        last_pos = curr_pos;
        pass_move(pos);
    } else {
        last_pos = curr_pos;
        play_move(pos, point);
    }
}

- (void)reset {
    free_tree(tree);
    empty_position(pos);
    last_pos = curr_pos;
    tree = new_tree_node(pos);
}

- (NSString *)stringFromCol:(NSInteger)col {
    NSString *cols = @"ABCDEFGHJKLMNOPQRSTUV";
    return [cols substringWithRange:NSMakeRange(col, 1)];
}

- (NSString *)stringFromRow:(NSInteger)row {
    return [NSString stringWithFormat:@"%ld", (long)(self.size - row)];
}

- (NSString *)stringFromPoint:(CGPoint)point {
    NSString *string = [NSString stringWithFormat:@"%@%@", [self stringFromCol:point.x], [self stringFromRow:point.y]];
    return string;
}

- (void)saveGame:(NSString *)filename {
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:self.defaultFilename];
    if (handle == nil) {
        [[NSFileManager defaultManager] createFileAtPath:self.defaultFilename contents:nil attributes:nil];
        handle = [NSFileHandle fileHandleForWritingAtPath:self.defaultFilename];
    }
    if (handle) {
        write(handle.fileDescriptor, pos, sizeof(Position));
    }
}

- (void)loadGame:(NSString *)filename {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:self.defaultFilename];
    if (handle) {
        Position position;
        size_t size = read(handle.fileDescriptor, &position, sizeof(Position));
        if (size == sizeof(Position)) {
            free_tree(tree);
            memcpy(pos, &position, sizeof(Position));
            tree = new_tree_node(pos);
        }
    }
}

- (NSString *)defaultPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    return documentPath;
}

- (NSString *)defaultFilename {
    return [self.defaultPath stringByAppendingPathComponent:@".lastpos"];
}

- (void)autoSaveGame {
    [self saveGame:self.defaultFilename];
}

- (void)autoLoadGame {
    [self loadGame:self.defaultFilename];
}

@end

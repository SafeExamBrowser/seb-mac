//
//  NSPasteboard+SaveRestore
//  SafeExamBrowser
//

#import "NSPasteboard+SaveRestore.h"


@implementation NSPasteboard (SaveRestore)

- (NSArray *)archiveObjects
{
    NSMutableArray *archive = [NSMutableArray array];
    for (NSPasteboardItem *item in [self pasteboardItems]) {
        NSPasteboardItem *archivedItem = [[NSPasteboardItem alloc] init];
        for (NSString *type in [item types]) {
            NSData *data = [item dataForType:type];
            if (data) {
                [archivedItem setData:data forType:type];
            }
        }
        [archive addObject:archivedItem];
    }
    return archive.copy;
}

- (void)restoreArchive:(NSArray *)archive
{
    NSMutableArray *copiedPasteboardItems = [NSMutableArray array];
    for (NSPasteboardItem *item in archive) {
        NSPasteboardItem *archivedItem = [[NSPasteboardItem alloc] init];
        for (NSString *type in [item types]) {
            NSData *data = [item dataForType:type];
            if (data) {
                [archivedItem setData:data forType:type];
            }
        }
        [copiedPasteboardItems addObject:archivedItem];
    }

    [self clearContents];
    [self writeObjects:copiedPasteboardItems];
}

@end

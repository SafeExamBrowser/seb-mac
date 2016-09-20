//
//  NSPasteboard+SaveRestore
//  SafeExamBrowser
//

@interface NSPasteboard (SaveRestore)

- (NSArray *)archiveObjects;
- (void)restoreArchive:(NSArray *)archive;

@end

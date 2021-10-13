//

#import "ZMSDKChatWindowController.h"
@interface ZMSDKChatMessage : NSObject
@property (copy,nonatomic) NSString *messageOwner;
@property (copy,nonatomic) NSString *messageContent;
@property (copy,nonatomic) NSString *messageDirect;
@end
@implementation ZMSDKChatMessage
@end
@interface ZMSDKChatWindowController ()<NSTextFieldDelegate,NSTableViewDelegate,NSTableViewDataSource>
@property (weak) IBOutlet NSTableView *chatListView;
@property (weak) IBOutlet NSPopUpButton *userListPopBtn;
@property (weak) IBOutlet NSTextField *chatContentTextField;
@property (weak,nonatomic) ZoomSDKMeetingActionController *meetActionController;
@property (strong,nonatomic) NSMutableArray <NSNumber *> *chatUserList;
@property (assign,nonatomic) unsigned int  currentSelectUserId;
@property (strong,nonatomic) NSMutableArray *messageList;
@end

@implementation ZMSDKChatWindowController
- (void)windowDidLoad {
    [super windowDidLoad];
}

- (void)cleanUp {
}

- (void)dealloc {
    [self cleanUp];
}

- (id)init
{
    self = [super initWithWindowNibName:@"ZMSDKChatWindowController" owner:self];
    if(self)
    {
        [self initUI];
        return self;
    }
    return nil;
}

- (void)initUI
{
    self.window.title = @"Chat";
    self.chatContentTextField.delegate = self;
    
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    if(meetingService)
    {
        self.meetActionController = [meetingService getMeetingActionController];
    }
    self.messageList = [[NSMutableArray alloc]init];
    
    [self updateUserList];
}


- (void)updateUserList {
    if (self.chatUserList) {
        [self.chatUserList removeAllObjects];
    } else {
        self.chatUserList = [[NSMutableArray alloc]init];
    }
    NSMutableArray <NSString *>*popItemArr = [[NSMutableArray alloc]init];
    [popItemArr addObject:@"Send to All"];
    NSArray *userIDArr = [self.meetActionController getParticipantsList];
    for (NSNumber *userId in userIDArr) {
        ZoomSDKUserInfo *userInfo = [_meetActionController getUserByUserID:userId.unsignedIntValue];
        NSString *userName = [userInfo getUserName];
        if (userName && userName.length >0 && ![userInfo isMySelf]) {
            [self.chatUserList addObject:userId];
            [popItemArr addObject:userName];
        }
    }
    
    [self.userListPopBtn addItemsWithTitles:popItemArr];
    
    for (NSMenuItem *menuItem in self.userListPopBtn.itemArray) {
        NSInteger index = [self.userListPopBtn.itemArray indexOfObject:menuItem];
        if (index == 0) {
            menuItem.tag = 0;
        } else {
            if (self.chatUserList.count >= index) {
                menuItem.tag = [[self.chatUserList objectAtIndex:index-1] unsignedIntValue];
            }
        }
    }
    
    if (self.currentSelectUserId != 0) {
        [self.userListPopBtn selectItemWithTag:self.currentSelectUserId];
    }
}
#define kChatMessageMaxCount 100
- (void)updateChatListWithNewMessage:(ZMSDKChatMessage *)chatMessage {
    [self.messageList addObject:chatMessage];
    if (self.messageList.count > kChatMessageMaxCount) {
        self.messageList = [[self.messageList subarrayWithRange:NSMakeRange(0, kChatMessageMaxCount)]mutableCopy];
    }
    [self.chatListView reloadData];
}


- (void)submitChatContent {
    
    NSInteger index = [self.userListPopBtn indexOfSelectedItem];
    unsigned int userId;
    if (index != 0 && self.chatUserList.count >= index) {
        userId = [self.chatUserList[index-1] unsignedIntValue];
    } else {
        userId = 0;
    }
    ZoomSDKChatMessageType messageType = (index != 0 )? ZoomSDKChatMessageType_To_Individual:ZoomSDKChatMessageType_To_All;
    ZoomSDKError error = [_meetActionController sendChat:_chatContentTextField.stringValue toUser:userId chatType:messageType];
    if (ZoomSDKError_Success == error) {
        _chatContentTextField.stringValue = @"";
    }
}

#pragma mark -- Action
- (IBAction)onUserListPopBtnClick:(id)sender {
    if (self.userListPopBtn.indexOfSelectedItem != 0 && self.chatUserList.count>=self.userListPopBtn.indexOfSelectedItem) {
        self.currentSelectUserId = [self.chatUserList[self.userListPopBtn.indexOfSelectedItem-1] unsignedIntValue];
    }  else {
        self.currentSelectUserId = 0;
    }
    [self updateUserList];
}


#pragma mark -- NSTextFieldDelegate
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if ([NSStringFromSelector(commandSelector) isEqualToString:@"insertNewline:"]) {
        
        if (([NSApplication sharedApplication].currentEvent.modifierFlags & NSEventModifierFlagShift) == 0) {
            [self submitChatContent];
            return YES;
        }
    }
    return NO;
}


#pragma mark -- ZoomSDKMeetingActionControllerDelegate
- (void)onChatMessageNotification:(ZoomSDKChatInfo*)chatInfo {
    
    unsigned int recUserId = chatInfo.getReceiverUserID;
    unsigned int sendUserId = chatInfo.getSenderUserID;
    if (chatInfo.getChatMessageType == ZoomSDKChatMessageType_To_All || chatInfo.getChatMessageType == ZoomSDKChatMessageType_To_All_Panelist  || (ZoomSDKChatMessageType_To_Individual && (recUserId == [[_meetActionController getMyself]getUserID] || sendUserId == [[_meetActionController getMyself] getUserID] ))) {
        ZMSDKChatMessage *chatMessage = [[ZMSDKChatMessage alloc]init];
        chatMessage.messageContent = chatInfo.getMsgContent;
        chatMessage.messageDirect = (chatInfo.getChatMessageType == ZoomSDKChatMessageType_To_All || chatInfo.getChatMessageType == ZoomSDKChatMessageType_To_All_Panelist) ?@"to All:":[NSString stringWithFormat:@"to %@:",chatInfo.getReceiverDisplayName];
        chatMessage.messageOwner = chatInfo.getSenderDisplayName;
        [self updateChatListWithNewMessage:chatMessage];
    }
}

#pragma mark -- NSTableViewDelegate


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.messageList.count;
}
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"ChatItem" owner:self];
    ZMSDKChatMessage *chatMsg = self.messageList[row];
    cellView.textField.stringValue = [NSString stringWithFormat:@"%@ %@ %@",chatMsg.messageOwner,chatMsg.messageDirect,chatMsg.messageContent];
    return cellView;
}

- (void)setMeetingMainWindowController:(ZMSDKMeetingMainWindowController *)meetingMainWindowController {
    _meetingMainWindowController = meetingMainWindowController;
    [self showPromptExplained];
}

- (void)showPromptExplained {
    NSString *chatPrompt = [self.meetActionController getChatLegalNoticesPrompt]?:@"";
    NSString *chatExplain = [self.meetActionController getChatLegalNoticesExplained]?:@"";
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"chat\nPrompt:%@\nexplain:%@",chatPrompt,chatExplain] defaultButton:@"ok" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@""];
    [alert beginSheetModalForWindow:_meetingMainWindowController.window completionHandler:nil];
}

@end

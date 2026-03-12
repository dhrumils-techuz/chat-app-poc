import 'package:get/get_navigation/src/root/internacionalization.dart';

class Keys {
  // Common
  static const String AppName = 'AppName';
  static const String OK = 'OK';
  static const String Yes = 'Yes';
  static const String No = 'No';
  static const String Cancel = 'Cancel';
  static const String Done = 'Done';
  static const String Save = 'Save';
  static const String Delete = 'Delete';
  static const String Edit = 'Edit';
  static const String Copy = 'Copy';
  static const String Forward = 'Forward';
  static const String Reply = 'Reply';
  static const String Retry = 'Retry';
  static const String Message = 'Message';
  static const String Error = 'Error';
  static const String Search = 'Search';
  static const String Loading = 'Loading';

  // Network
  static const String You_are_Offline = 'You_are_Offline';
  static const String Please_connect_to_internet = 'Please_connect_to_internet';
  static const String Some_error_occurred = 'Some_error_occurred';
  static const String Session_Expired = 'Session_Expired';
  static const String Unable_to_process_your_request_due_to_poor_internet_connection =
      'Unable_to_process_your_request_due_to_poor_internet_connection';

  // Auth
  static const String Sign_In = 'Sign_In';
  static const String Sign_Out = 'Sign_Out';
  static const String Log_out = 'Log_out';
  static const String Email = 'Email';
  static const String Password = 'Password';
  static const String Welcome_Back = 'Welcome_Back';
  static const String Sign_in_to_continue = 'Sign_in_to_continue';
  static const String Forgot_Password = 'Forgot_Password';
  static const String Are_you_sure_you_want_to_logout = 'Are_you_sure_you_want_to_logout';

  // Chat
  static const String Chats = 'Chats';
  static const String New_Chat = 'New_Chat';
  static const String New_Group = 'New_Group';
  static const String Type_a_message = 'Type_a_message';
  static const String Online = 'Online';
  static const String Offline = 'Offline';
  static const String Typing = 'Typing';
  static const String Last_seen = 'Last_seen';
  static const String Yesterday = 'Yesterday';
  static const String Today = 'Today';
  static const String No_messages_yet = 'No_messages_yet';
  static const String Start_a_conversation = 'Start_a_conversation';
  static const String No_conversations = 'No_conversations';
  static const String Search_conversations = 'Search_conversations';
  static const String Search_contacts = 'Search_contacts';

  // Message types
  static const String Photo = 'Photo';
  static const String Voice_message = 'Voice_message';
  static const String Document = 'Document';
  static const String File = 'File';

  // Message actions
  static const String Delete_message = 'Delete_message';
  static const String Delete_for_everyone = 'Delete_for_everyone';
  static const String Delete_for_me = 'Delete_for_me';
  static const String Message_deleted = 'Message_deleted';
  static const String Copied_to_clipboard = 'Copied_to_clipboard';

  // Group
  static const String Group_Info = 'Group_Info';
  static const String Add_Members = 'Add_Members';
  static const String Remove_Member = 'Remove_Member';
  static const String Make_Admin = 'Make_Admin';
  static const String Leave_Group = 'Leave_Group';
  static const String Group_Name = 'Group_Name';
  static const String Members = 'Members';

  // Media
  static const String Camera = 'Camera';
  static const String Gallery = 'Gallery';
  static const String Send = 'Send';
  static const String Sending = 'Sending';
  static const String Failed_to_send = 'Failed_to_send';
  static const String File_too_large = 'File_too_large';
  static const String Unsupported_file_type = 'Unsupported_file_type';

  // Folders
  static const String All_Chats = 'All_Chats';
  static const String Folders = 'Folders';
  static const String Create_Folder = 'Create_Folder';
  static const String Folder_Name = 'Folder_Name';

  // Empty states
  static const String No_results_found = 'No_results_found';
  static const String Something_went_wrong = 'Something_went_wrong';
}

class ChatStringEnUS {
  static const engMap = {
    // Common
    Keys.AppName: 'MediChat',
    Keys.OK: 'OK',
    Keys.Yes: 'Yes',
    Keys.No: 'No',
    Keys.Cancel: 'Cancel',
    Keys.Done: 'Done',
    Keys.Save: 'Save',
    Keys.Delete: 'Delete',
    Keys.Edit: 'Edit',
    Keys.Copy: 'Copy',
    Keys.Forward: 'Forward',
    Keys.Reply: 'Reply',
    Keys.Retry: 'Retry',
    Keys.Message: 'Message',
    Keys.Error: 'Error',
    Keys.Search: 'Search',
    Keys.Loading: 'Loading...',

    // Network
    Keys.You_are_Offline: "You're Offline",
    Keys.Please_connect_to_internet: 'Please connect to internet',
    Keys.Some_error_occurred: 'Some error occurred',
    Keys.Session_Expired: 'Session Expired',
    Keys.Unable_to_process_your_request_due_to_poor_internet_connection:
        'Unable to process your request due to poor internet connection',

    // Auth
    Keys.Sign_In: 'Sign In',
    Keys.Sign_Out: 'Sign Out',
    Keys.Log_out: 'Log out',
    Keys.Email: 'Email',
    Keys.Password: 'Password',
    Keys.Welcome_Back: 'Welcome Back',
    Keys.Sign_in_to_continue: 'Sign in to continue',
    Keys.Forgot_Password: 'Forgot Password?',
    Keys.Are_you_sure_you_want_to_logout: 'Are you sure you want to log out?',

    // Chat
    Keys.Chats: 'Chats',
    Keys.New_Chat: 'New Chat',
    Keys.New_Group: 'New Group',
    Keys.Type_a_message: 'Type a message...',
    Keys.Online: 'Online',
    Keys.Offline: 'Offline',
    Keys.Typing: 'typing...',
    Keys.Last_seen: 'last seen',
    Keys.Yesterday: 'Yesterday',
    Keys.Today: 'Today',
    Keys.No_messages_yet: 'No messages yet',
    Keys.Start_a_conversation: 'Start a conversation',
    Keys.No_conversations: 'No conversations',
    Keys.Search_conversations: 'Search conversations',
    Keys.Search_contacts: 'Search contacts',

    // Message types
    Keys.Photo: 'Photo',
    Keys.Voice_message: 'Voice message',
    Keys.Document: 'Document',
    Keys.File: 'File',

    // Message actions
    Keys.Delete_message: 'Delete Message',
    Keys.Delete_for_everyone: 'Delete for Everyone',
    Keys.Delete_for_me: 'Delete for Me',
    Keys.Message_deleted: 'This message was deleted',
    Keys.Copied_to_clipboard: 'Copied to clipboard',

    // Group
    Keys.Group_Info: 'Group Info',
    Keys.Add_Members: 'Add Members',
    Keys.Remove_Member: 'Remove Member',
    Keys.Make_Admin: 'Make Admin',
    Keys.Leave_Group: 'Leave Group',
    Keys.Group_Name: 'Group Name',
    Keys.Members: 'Members',

    // Media
    Keys.Camera: 'Camera',
    Keys.Gallery: 'Gallery',
    Keys.Send: 'Send',
    Keys.Sending: 'Sending...',
    Keys.Failed_to_send: 'Failed to send',
    Keys.File_too_large: 'File is too large. Maximum size is 25 MB.',
    Keys.Unsupported_file_type: 'Unsupported file type',

    // Folders
    Keys.All_Chats: 'All Chats',
    Keys.Folders: 'Folders',
    Keys.Create_Folder: 'Create Folder',
    Keys.Folder_Name: 'Folder Name',

    // Empty states
    Keys.No_results_found: 'No results found',
    Keys.Something_went_wrong: 'Something went wrong',
  };
}

class ChatMessages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': ChatStringEnUS.engMap,
      };
}

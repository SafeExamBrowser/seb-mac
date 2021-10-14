/*****************************************************************************
*
* Copyright (C) 2013, Zoom Video Communications, Inc
*
* History:
*	Nov 2013 - Created - ken.ding@zoom.us
*	
*****************************************************************************/

#ifndef __ANNO_TYPES_H__
#define __ANNO_TYPES_H__

#include <vector>
#include <string>

// ----------------------------------------------------------------------------
// Define macro switches for decroration
// ----------------------------------------------------------------------------

#ifndef IN
  #define IN
#endif

#ifndef OUT
  #define OUT
#endif

#ifndef OPTIONAL
  #define OPTIONAL
#endif

#ifndef singleton_static
  #define singleton_static static
#endif

#ifndef var_static
  #define var_static static
#endif

// ----------------------------------------------------------------------------
//	Turn it on to enable factor methods
// ----------------------------------------------------------------------------

#if defined USE_CLASS_INTERFACE && !defined ANNO_DLLEXPORT
  #define ANNO_DLLEXPORT __declspec(dllexport)
#else
  #define ANNO_DLLEXPORT
#endif

// ----------------------------------------------------------------------------
// Define primitive data types that are shared by this module and external
// applications
// ----------------------------------------------------------------------------

#ifndef Bool8
  typedef bool Bool8;
#endif

#ifndef UInt8
  typedef unsigned char UInt8;
#endif

#ifndef Int8
  typedef char Int8;
#endif

#ifndef UInt16
  typedef unsigned short UInt16;
#endif

#ifndef Int16
  typedef short Int16;
#endif

#ifndef UInt32
  #if __LP64__
    typedef unsigned int UInt32;
  #else
    typedef unsigned long UInt32;
  #endif
#endif

#ifndef Int32 
  typedef int Int32;
#endif

#ifndef Int64
  typedef long long Int64;
#endif

#ifndef Float32
  typedef float Float32;
#endif

#ifndef Double64
  typedef double Double64;
#endif

#ifndef NODEID
  typedef UInt32 NODEID;
#endif

#ifndef NULL_NODE_ID
  #define NULL_NODE_ID	0xffffffff
#endif

#ifndef BROADCAST_NODE_ID
  #define BROADCAST_NODE_ID		0x00000000
#endif

#ifndef INT_MAX
    #define INT_MAX		0xffffffff
#endif

#ifndef DOUBLE64_EPSILON
    #define DOUBLE64_EPSILON    2.2204460492503131E-16
#endif

#ifndef AnnoWnd
  typedef void *AnnoWnd;	// handle
#endif

#ifndef AnnoGc
  typedef void *AnnoGc;	// handle
#endif

#ifndef AnnoImage
  typedef void *AnnoImage;	// handle
#endif

#ifndef WPARAM
  #if defined (__IOS__) || defined (__MACOS__)
    typedef unsigned long WPARAM;
  #elif defined (__LINUX_CLIENT__)
    typedef unsigned long WPARAM;
  #elif defined _WIN64
	typedef unsigned __int64 WPARAM;
  #elif defined __aarch64__  || defined __x86_64__
	typedef unsigned long WPARAM;
  #else
    typedef unsigned int WPARAM;
  #endif
#endif

#ifndef LPARAM
  #if defined (__IOS__) || defined (__MACOS__) 
    typedef unsigned long LPARAM;
  #elif defined _WIN64
	typedef __int64 LPARAM;
  #else
    typedef long LPARAM;
  #endif
#endif

#define AnnoFloatEqual(f1, f2) ( (f1) > (f2) ? ((f1) - (f2)) < 1E-6: ((f2) - (f1)) < 1E-6 )

typedef struct tagAnnoPoint
{
    Int32	x;
    Int32	y;

    bool operator== (const tagAnnoPoint& point) const
    {
        return (x == point.x) && (y == point.y);
    }
    
    bool operator!= (const tagAnnoPoint& point) const
    {
        return (x != point.x) || (y != point.y);
    }

    bool operator< (const tagAnnoPoint& point) const
    {
        return x < point.x || ((x == point.x) && y < point.y);
    }
} AnnoPoint;

typedef AnnoPoint AnnoOffset;

typedef struct tagAnnoPointF
{
    Float32   x;
    Float32   y;

    tagAnnoPointF()
    {
        x = y = 0.0f;
    }

    tagAnnoPointF(Float32 __x, Float32 __y)
    {
        x = __x;
        y = __y;
    }

    bool operator== (const tagAnnoPointF& pointF) const
    {
        return AnnoFloatEqual(x, pointF.x) && AnnoFloatEqual(y, pointF.y);
    }
    
    bool operator!= (const tagAnnoPointF& pointF) const
    {
        return !AnnoFloatEqual(x, pointF.x) || !AnnoFloatEqual(y, pointF.y);
    }

    bool operator< (const tagAnnoPointF& pointF) const
    {
        return x < pointF.x || (AnnoFloatEqual(x, pointF.x) && y < pointF.y);
    }
} AnnoPointF;

typedef AnnoPointF AnnoOffsetF;

typedef struct tagAnnoSize
{
    Int32        width;
    Int32        height;

    bool IsEmpty() const
    {
        return (0 >= width) || (0 >= height);
    }

    bool operator== (const tagAnnoSize& size) const
    {
        return (width == size.width) && (height == size.height);
    }
    
    bool operator!= (const tagAnnoSize& size) const
    {
        return (width != size.width) || (height != size.height);
    }
} AnnoSize;

typedef struct tagAnnoSizeF
{
    Float32   width;
    Float32   height;

    bool IsEmpty() const
    {
        return (0 > width) || (0 > height);
    }

    bool operator== (const tagAnnoSizeF& sizeF) const
    {
        return AnnoFloatEqual(width, sizeF.width) && AnnoFloatEqual(height, sizeF.height);
    }
    
    bool operator!= (const tagAnnoSizeF& sizeF) const
    {
        return !AnnoFloatEqual(width, sizeF.width) || !AnnoFloatEqual(height, sizeF.height);
    }
} AnnoSizeF;

typedef struct tagAnnoRect
{
    Int32		left;
    Int32		top;
    Int32		right;
    Int32		bottom;

    Int32 Width() const
    {
        return right - left;
    }

    Int32 Height() const
    {
        return bottom - top;
    }
	
    bool IsEmpty() const
    {
        return (left >= right) || (top >= bottom);
    }

    bool operator== (const tagAnnoRect& rect) const
    {
        return (left == rect.left) && (top == rect.top) && (right == rect.right) && (bottom == rect.bottom);
    }
    
    bool operator!= (const tagAnnoRect& rect) const
    {
        return (left != rect.left) || (top != rect.top) || (right != rect.right) || (bottom != rect.bottom);
    }
} AnnoRect;

typedef struct tagAnnoRectF
{
    Float32        left;
    Float32        top;
    Float32        right;
    Float32        bottom;

    tagAnnoRectF()
        : left(0)
        , top(0)
        , right(0)
        , bottom(0)
    {
    }
	
    tagAnnoRectF(Float32 __left, Float32 __top, Float32 __right, Float32 __bottom)
        : left(__left)
        , top(__top)
        , right(__right)
        , bottom(__bottom)
    {
    }
	
    AnnoPointF Origin() const
    {
        return AnnoPointF(left, top);
    }

    Float32 Width() const
    {
        return right - left;
    }
	
    Float32 Height() const
    {
        return bottom - top;
    }
	
    bool operator== (const tagAnnoRectF& rectF) const
    {
         bool bEqual = AnnoFloatEqual(left, rectF.left) && AnnoFloatEqual(top, rectF.top) &&
                        AnnoFloatEqual(right, rectF.right) && AnnoFloatEqual(bottom, rectF.bottom);
         return bEqual;
    }
    
    bool operator!= (const tagAnnoRectF& rectF) const
    {
        bool bEqual = AnnoFloatEqual(left, rectF.left) && AnnoFloatEqual(top, rectF.top) &&
        AnnoFloatEqual(right, rectF.right) && AnnoFloatEqual(bottom, rectF.bottom);
        return !bEqual;
    }
} AnnoRectF;

typedef struct tagAnnoWindow
{
    AnnoWnd		wndDrawing;		// the window on which drawing will be made, NULL means it's a whole or portion of monitor on sharer side
    AnnoRect	drawBounding;	// drawing bounding related to wndDrawing's client area, in pixel
    AnnoOffset	contentOffset;	// the x/y offset of content related to drawBounding before zooming takes effective
    Float32		zoomFactor;		// 100% = 1.0, 80% = 0.80
} AnnoWindow;

typedef struct tagAnnoWindowMultiMonitor
{
    AnnoRect	monitorRect;	// the rectangle of monitor on which the whole or portion of monitor is being shared
    AnnoRect	sharedRect;		// the rectangle of area beging shared
    Float32		dpiScaleOfMonitor;	// the DPI scale of the monitor on which the whole or portion of monitor is being shared

} AnnoWindowMultiMonitor;

// ----------------------------------------------------------------------------
//	Supported Annotation Mode, used by structure AnnoStartupInput
// ----------------------------------------------------------------------------

typedef enum tagAnnoMode
{
	ANNO_MODE_APPSHARE,
	ANNO_MODE_SCREENSHARE_WB,
	ANNO_MODE_DOCSHARE, // Deprecated mode
	ANNO_MODE_CHAT_SCREENSHOT,
	ANNO_MODE_NONE
} AnnoMode;

// ----------------------------------------------------------------------------
//	Supported annotation tool, used by AnnoBase::SetAnnoCursor, 
//		AnnoBase::SetAnnoTool, AnnoBase::GetAnnoTool
// ----------------------------------------------------------------------------

typedef enum tagAnnoToolType
{
	ANNO_TOOL_TYPE_NONE,
	ANNO_TOOL_TYPE_PEN,
	ANNO_TOOL_TYPE_HIGHLIGHTER,
	ANNO_TOOL_TYPE_SPOTLIGHT,
	ANNO_TOOL_TYPE_ARROW,
	ANNO_TOOL_TYPE_TEXTBOX,
	ANNO_TOOL_TYPE_PICTURE,
	ANNO_TOOL_TYPE_ERASER,
	ANNO_TOOL_TYPE_BRUSH_ERASER,
	ANNO_TOOL_TYPE_PICKER,
	ANNO_TOOL_TYPE_SELECTOR,
	ANNO_TOOL_TYPE_AUTO_LINE,
	ANNO_TOOL_TYPE_AUTO_ARROW1,
	ANNO_TOOL_TYPE_AUTO_ARROW2,
	ANNO_TOOL_TYPE_AUTO_RECTANGLE,
	ANNO_TOOL_TYPE_AUTO_RECTANGLE_SEMI_FILL,
	ANNO_TOOL_TYPE_AUTO_ROUNDEDRECTANGLE,
	ANNO_TOOL_TYPE_AUTO_ROUNDEDRECTANGLE_SEMI_FILL,
	ANNO_TOOL_TYPE_AUTO_ELLIPSE,
	ANNO_TOOL_TYPE_AUTO_ELLIPSE_SEMI_FILL,
	// added 3.6
	ANNO_TOOL_TYPE_AUTO_DOUBLE_ARROW,
	ANNO_TOOL_TYPE_AUTO_RECTANGLE_FILL,
	ANNO_TOOL_TYPE_AUTO_ROUNDEDRECTANGLE_FILL,
	ANNO_TOOL_TYPE_AUTO_ELLIPSE_FILL,
	ANNO_TOOL_TYPE_AUTO_DIAMOND,
	ANNO_TOOL_TYPE_AUTO_STAMP_ARROW,
	ANNO_TOOL_TYPE_AUTO_STAMP_CHECK,
	ANNO_TOOL_TYPE_AUTO_STAMP_X,
	// added for ZRT 2.0 Mar 2017
	ANNO_TOOL_TYPE_MULTI_FLAT_PEN,
	ANNO_TOOL_TYPE_MULTI_FLAT_ERASER,
	ANNO_TOOL_TYPE_MULTI_THICKNESS_PEN,
	// added June 2018 
	ANNO_TOOL_TYPE_AUTO_STAMP_STAR,
	ANNO_TOOL_TYPE_AUTO_STAMP_HEART,
	ANNO_TOOL_TYPE_AUTO_STAMP_QM,
	// added for ZRT Mar 2019
	ANNO_TOOL_TYPE_MULTI_SHAPE_DETECTOR,
	ANNO_TOOL_TYPE_MULTI_TEXT_DETECTOR,
    //added Feb 2021
    ANNO_TOOL_TYPE_FADE_PEN,
    ANNO_TOOL_TYPE_MOSAIC,
	NUMBER_OF_ANNO_TOOL_TYPE
} AnnoToolType;

typedef enum tagAnnoToolState
{
    ANNO_TOOL_STATE_IDLE,
    ANNO_TOOL_STATE_READY,
    ANNO_TOOL_STATE_EDITING_SHAPE,
    ANNO_TOOL_STATE_EDITING_TEXT
} AnnoToolState;

// ----------------------------------------------------------------------------
//	AnnoBase event type, used by AnnoBaseObserver::OnAnnoBaseNotify
// ----------------------------------------------------------------------------

typedef struct tagAnnoKeyboardInfo
{
    AnnoSize    keyboardSize;
    AnnoRect    textInputFrame;
} AnnoKeyboardInfo;

typedef enum tagAnnoWhiteboardEvent
{
	ANNO_WHITEBOARD_EVENT_WINDOW_CREATED,
	ANNO_WHITEBOARD_EVENT_WINDOW_SHOWN,
	ANNO_WHITEBOARD_EVENT_WINDOW_HIDDEN,
	ANNO_WHITEBOARD_EVENT_WINDOW_DESTROYED,
	ANNO_WHITEBOARD_EVENT_WINDOW_MOVED,
	ANNO_WHITEBOARD_EVENT_WINDOW_RESIZED,
	ANNO_WHITEBOARD_EVENT_WINDOW_TO_BE_CLOSED,
	ANNO_WHITEBOARD_EVENT_WINDOW_MINIMIZED,
	ANNO_WHITEBOARD_EVENT_WINDOW_SET_TITLE
} AnnoWhiteboardEvent;

typedef enum tagAnnoEventType
{
	//notify to session
	ANNO_EVENT_STARTED_UP				= 0x0000,		// to notify that annotation session has just started up
	ANNO_EVENT_SHUT_DOWN				= 0x0001,		// to notify that annotation session has just shut down
	ANNO_EVENT_ROOT_WND					= 0x0002,		// to notify that annotation windows has been created to ensure other windows to be on top of it
	ANNO_EVENT_TOOL_CHANGED				= 0x0003,		// to notify that current annotation tool has been changed (by mouse right click or whatever means that unknown to uppper layer)
	ANNO_EVENT_CAN_UNDO_REDO			= 0x0004,		// to notify if or not undo/redo are available so that UI can enable/disable menu/toolbar respondingly
	ANNO_EVENT_HAS_ANNOTATION			= 0x0005,		// to notify if or not current page has annotation so that UI can enable/disable menu/toolbar icon "Clear All"
	ANNO_EVENT_LOCAL_DRAWING_STATE		= 0x0006,		// to notify that local drawing has been started (ready to accpet local mouse or touch events to draw, or drawing is in progress, etc.) or stopped (not to accpet local mouse or touch events, for example "Mouse" mode)
	ANNO_EVENT_WB_WINDOW_STATE			= 0x0007,		// to notify that WB window has been showed up or hidden
	ANNO_EVENT_DRAW_CHANGED				= 0x0008,		// to notify that draw changed
	ANNO_EVENT_APPLE_STYLUS_DETECTED	= 0x0009,		// to notify that an stylus type input detected on IOS
	ANNO_EVENT_ZR_WINDOW_CHANGED		= 0x000A,		// to notify that ZR windows has been changed
	ANNO_EVENT_REQUEST_ANNOTATOR_NAME	= 0x000B,		// to notify that current drawing changed
	ANNO_EVENT_ZR_DRAW_ANNOTATE			= 0x000C,		// to notify that zr draw annotate
	ANNO_EVENT_PAGE_CHANGED				= 0x000D,		// to notify that page number has changed
	ANNO_EVENT_RECOGNIZE_CHANGED		= 0x000E,		// to notify that reconization text changed
	ANNO_EVENT_PENCIL_DOUBLETAP_PALETTE	= 0x000F,		// to notify that a double tap event has been detected to show color palette
	ANNO_EVENT_UPDATE_TOOLBAR_UI		= 0x0010,		// to notify that toobard ui need to changed
	ANNO_EVENT_RENDER_NOTIFY			= 0x0011,		// to notify that render asynchronous processing return(ios save content..)
	ANNO_EVENT_CONTENT_SAVING_STATE     = 0x0012,		// to notify that the pdfsaving start or the pdfsaving end;
	ANNO_EVENT_ZR_TAP_DETECTED			= 0x0013,		// to notify that tap detected from input and ZRT should show/hide the toolbar, zoom room only
	ANNO_EVENT_TOOL_STATE_CHANGED		= 0x0014,		// to notify that tool state has changed, this is used by VDI & ZR auto hide
	//notify to Media client manage module
	//...0x1000

	//notify to Nydus module
	ANNO_EVENT_SHARER_PROPERTY_CHANGED	= 0x0200,		// to notify Nydus module that remote sharer's doc property has been changed and need Nydus to reset annowindow

	//notify to AS module
	ANNO_EVENT_REMOTE_DRAWING_TO_START	= 0x0300,		// to notify AS module know that remote participants are going to add annotation to presenter's shared screen.
	ANNO_EVENT_REMOTE_DRAW_FINISHED		= 0x0301,		// to notify that a remote drawing command has been just executed on local so that uppper layer (AS) sampling program knows where to retrive the dirty region for best perofrmance
	ANNO_EVENT_CAPTURE_CHANGED			= 0x0302,		// to notify AS module that new difference of frame has been made and needs AS to refresh

    ANNO_EVENT_WB_TITLE_CHANGED,                        // to notify that whiteboard title has been changed.

    ANNO_EVENT_CHECK_REMOVE_ALL_BY_HOST,			    // to notify that this user want to clear all datas, we need to check is host/cohost
    ANNO_EVENT_CHECK_RESTORE_ALL_BY_HOST,			    // to notify that this user want to restore all datas, we need to check is host/cohost
	
    NUMBER_OF_ANNO_EVENT_TYPE
} AnnoEventType;

// ----------------------------------------------------------------------------
//	AnnoBase input type: an abstraction of mouse, touch and keyboard input on 
//   all platforms
// ----------------------------------------------------------------------------

typedef enum tagAnnoInputType
{
	ANNO_INPUT_TYPE_NONE		= 0,

	ANNO_INPUT_TYPE_FOCUS		= 0x0007,	// WM_SETFOCUS
	ANNO_INPUT_TYPE_KILLFOCUS	= 0x0008,	// WM_KILLFOCUS
	ANNO_INPUT_TYPE_SETCURSOR	= 0x0020,	// WM_SETCURSOR

	ANNO_INPUT_TYPE_KEYDOWN		= 0x0100,	// WM_KEYDOWN
	ANNO_INPUT_TYPE_KEYUP		= 0x0101,	// WM_KEYUP
	ANNO_INPUT_TYPE_CHAR		= 0x0102,	// WM_CHAR

	ANNO_INPUT_TYPE_MOVE		= 0x0200,	// WM_MOUSEMOVE
	ANNO_INPUT_TYPE_LDOWN		= 0x0201,	// WM_LBUTTONDOWN
	ANNO_INPUT_TYPE_LUP			= 0x0202,	// WM_LBUTTONUP
	ANNO_INPUT_TYPE_LDCLICK		= 0x0203,	// WM_LBUTTONDBLCLK
	ANNO_INPUT_TYPE_RDOWN		= 0x0204,	// WM_RBUTTONDOWN
	ANNO_INPUT_TYPE_RUP			= 0x0205,	// WM_RBUTTONUP
	ANNO_INPUT_TYPE_RDCLICK		= 0x0206,	// WM_RBUTTONDBLCLK
	ANNO_INPUT_TYPE_MDOWN		= 0x0207,	// WM_MBUTTONDOWN
	ANNO_INPUT_TYPE_MUP			= 0x0208,	// WM_MBUTTONUP
	ANNO_INPUT_TYPE_MDCLICK		= 0x0209,	// WM_MBUTTONDBLCLK

	ANNO_INPUT_TYPE_POINTER_UPDATE			= 0x0245,
	ANNO_INPUT_TYPE_POINTER_DOWN			= 0x0246,
	ANNO_INPUT_TYPE_POINTER_UP				= 0x0247,
	ANNO_INPUT_TYPE_POINTER_ENTER			= 0x0249,
	ANNO_INPUT_TYPE_POINTER_LEAVE			= 0x024A,
	ANNO_INPUT_TYPE_POINTER_ACTIVATE		= 0x024B,
	ANNO_INPUT_TYPE_POINTER_CAPTURECHANGED	= 0x024C,
    
    ANNO_INPUT_TYPE_USER_BEGIN           = 0x0400 + 501,  // 0x400 = WM_USER
	ANNO_INPUT_TYPE_USER_LBUTTONDOWN,
	ANNO_INPUT_TYPE_USER_LBUTTONUP,
	ANNO_INPUT_TYPE_USER_MOUSEMOVE,
	ANNO_INPUT_TYPE_USER_RBUTTONDOWN,
	ANNO_INPUT_TYPE_USER_RBUTTONUP,
	ANNO_INPUT_TYPE_USER_END,

	ANNO_INPUT_TYPE_CANCEL			= 0x0500,
    
    ANNO_INPUT_TYPE_FLAGS_CHANGED   = 0x600, // Mac OSX flagsChanged
} AnnoInputType;

// ----------------------------------------------------------------------------
//the local File type
// ----------------------------------------------------------------------------
typedef enum tagAnnoFileType
{
	ANNO_FILE_TYPE_UNDEFINED			= 0x00,
	ANNO_FILE_TYPE_IMAGE_PNG			= 0x01,
	ANNO_FILE_TYPE_IMAGE_JPG			= 0x02,
	//ANNO_FILE_TYPE_SVG_NATIVE			= 3, // internal binary format
	NUMBER_OF_ANNO_FILE_TYPE
}AnnoFileType;

typedef enum tagAnnoVirtualKey
{
	ANNO_VIRTUAL_KEY_BACK		= 0x08,
	ANNO_VIRTUAL_KEY_SHIFT		= 0x10,
	ANNO_VIRTUAL_KEY_CONTROL	= 0x11,
	ANNO_VIRTUAL_KEY_ALT		= 0x12,
	ANNO_VIRTUAL_KEY_DELETE		= 0x2E,
    ANNO_VIRTUAL_KEY_Z          = 0x5A,
    ANNO_VIRTUAL_KEY_F1         = 0x70,
    ANNO_VIRTUAL_KEY_F2         = 0x71,
    ANNO_VIRTUAL_KEY_F3         = 0x72,
    ANNO_VIRTUAL_KEY_F4         = 0x73,
    ANNO_VIRTUAL_KEY_F5         = 0x74,
    ANNO_VIRTUAL_KEY_F6         = 0x75,
    ANNO_VIRTUAL_KEY_F7         = 0x76,
    ANNO_VIRTUAL_KEY_F8         = 0x77,
    ANNO_VIRTUAL_KEY_F9         = 0x78,
    ANNO_VIRTUAL_KEY_EQUAL      = 0xBB,
    ANNO_VIRTUAL_KEY_MINUS      = 0xBD,
} AnnoVirtualKey;

typedef enum tagAnnoFlagKey
{
    ANNO_FLAG_KEY_SHIFT         = 0x01,
    ANNO_FLAG_KEY_CONTROL       = 0x02,
    ANNO_FLAG_KEY_ALT           = 0x04
} AnnoFlagKey;

// ----------------------------------------------------------------------------
//	Type used by AnnoBase::SetAnnoColor
// ----------------------------------------------------------------------------

typedef enum tagAnnoColorIndex
{
	ANNO_COLOR_INDEX_ALL			= 0,
	ANNO_COLOR_INDEX_PEN			= 1,
	ANNO_COLOR_INDEX_HIGHLIGHTER	= 2,
	ANNO_COLOR_INDEX_ARROW			= 3,
	ANNO_COLOR_INDEX_SPOTLIGHT		= 4,
	ANNO_COLOR_INDEX_TEXT			= 5,
	ANNO_COLOR_INDEX_AUTO_RECTANGLE	= 6,
	ANNO_COLOR_INDEX_AUTO_ELLIPSE	= 7,
	ANNO_COLOR_INDEX_AUTO_ARROW1	= 8,
	ANNO_COLOR_INDEX_AUTO_ARROW2	= 9,
	NUMBER_OF_ANNO_COLOR_INDEX
} AnnoColorIndex;

// ----------------------------------------------------------------------------
//	Type used by all methods for return result
// ----------------------------------------------------------------------------

typedef enum tagAnnoError
{
    ANNO_SUCCEED    = 0x00000000,
    ANNO_OK         = ANNO_SUCCEED,

    ANNO_FAILED     = 0x00000001
} AnnoError;

// ----------------------------------------------------------------------------
//	Type used by AnnoBase::AnnoStartup and AnnoBase::NewWhiteboard
// ----------------------------------------------------------------------------

typedef struct tagAnnoStartupInput
{
	AnnoMode		annoMode;
	bool			isPresenter;
	NODEID			appId;
	const wchar_t*	appName;		// NULL ended unicode string
	NODEID			sharerId;
	UInt16          undoLevel;
} AnnoStartupInput;

typedef struct tagAnnoInput
{
	AnnoInputType	inputType;
	WPARAM          wParam;
	LPARAM          lParam;
} AnnoInput;

// ----------------------------------------------------------------------------
//	Configurations
// ----------------------------------------------------------------------------

typedef enum tagWbConfigMask
{
    WB_CONFIG_NULL                              = 0x00000000,
	WB_CONFIG_NO_WINDOW_FRAME			        = 0x00000001,
	WB_CONFIG_ALWAYS_FULLSCREEN			        = 0x00000002,
	WB_CONFIG_NEEDS_VIRTUAL_KEYBOARD	        = 0x00000004,
	WB_CONFIG_TOPMOST_WINDOW			        = 0x00000008,
	WB_CONFIG_ENABLE_MULTI_TOUCH		        = 0x00000010,
    WB_CONFIG_ENABLE_SAVE                       = 0x00000020,
    WB_CONFIG_ENABLE_HARDWARE_ACCELERATION      = 0x00000040,
    WB_CONFIG_ENABLE_NAME_TAG                   = 0x00000080
} WbConfigMask;

typedef UInt32 WbConfig;

typedef enum tagAnnoConfigMask
{
	ANNO_CONFIG_NULL					        = 0x00000000,
	ANNO_CONFIG_NEEDS_VIRTUAL_KEYBOARD	        = 0x00000001,
	ANNO_CONFIG_ENABLE_MULTI_TOUCH		        = 0x00000002,
	ANNO_CONFIG_DISABLE_DESKTOP_HOOK	        = 0x00000004,
	ANNO_CONFIG_DISABLE_ARROW_WINDOW	        = 0x00000008,
	ANNO_CONFIG_ENABLE_DIRTY_REFRESH	        = 0x00000010,
	ANNO_CONFIG_MOBILE_SHARE_WB			        = 0x00000020,
	ANNO_CONFIG_ENABLE_SHARE_ZOOM_WINDOW        = 0x00000040,
    ANNO_CONFIG_ENABLE_SAVE                     = 0x00000080,
    ANNO_CONFIG_ENABLE_HARDWARE_ACCELERATION    = 0x00000100,
    ANNO_CONFIG_ENABLE_NAME_TAG                 = 0x00000200
} AnnoConfigMask;

typedef UInt32 AnnoConfig;

// ----------------------------------------------------------------------------
//	The bitmap data storage format type
// ----------------------------------------------------------------------------
typedef enum tagAnnoBitmapFormat
{
	ANNO_BITMAP_FORMAT_NULL		= 0x0000,
	ANNO_BITMAP_FORMAT_BGRA32	= 0x0001,	// Windows DIB
	ANNO_BITMAP_FORMAT_RGBA32	= 0x0002,	// Mac CGContext
    ANNO_BITMAP_FORMAT_RGB24    = 0x0003,
    ANNO_BITMAP_FORMAT_RGB32    = 0x0004,
    ANNO_BITMAP_FORMAT_ARGB32   = 0x0005,
    ANNO_BITMAP_FORMAT_PARGB32  = 0x0006,
	ANNO_BITMAP_FORMAT_NUMBER
}AnnoBitmapFormat;


// ----------------------------------------------------------------------------
//	Page Operation Type used by AnnoEvent::ANNO_EVENT_PAGE_CHANGED
// ----------------------------------------------------------------------------
typedef enum tagAnnoPageOperation
{
	ANNO_PAGE_OPRATION_NONE		= 0x0000,
	ANNO_PAGE_OPRATION_ADD		= 0x0001,
	ANNO_PAGE_OPRATION_REMOVE	= 0x0002,
	ANNO_PAGE_OPRATION_RESTORE	= 0x0003,
	ANNO_PAGE_OPRATION_SWITCH	= 0x0004,
	ANNO_PAGE_OPRATION_NUMBER
}AnnoPageOperation;

typedef struct tagAnnoPageChangeInfo
{
	AnnoPageOperation	pageOp;
	NODEID				pageId;
	Int32				curPageIdx;
	Int32				totalPageNum;

	tagAnnoPageChangeInfo()
	{
		pageOp = ANNO_PAGE_OPRATION_NONE;
		pageId = NULL_NODE_ID;
		curPageIdx = totalPageNum = 0;
	}
}AnnoPageChangeInfo;

typedef enum tagAnnoSaveState
{
    ANNO_SAVE_END = 0,
    ANNO_SAVE_START = 1
} AnnoSaveState;

typedef enum tagAnnoSaveType
{
    ANNO_SAVE_NONE          = 0x00000000,
    ANNO_SAVE_PNG           = 0x00000001, 
    ANNO_SAVE_PDF           = 0x00000002,
    ANNO_SAVE_PNG_MEMORY    = 0x00000003,
    ANNO_SAVE_PDF_MEMORY    = 0x00000004,
    ANNO_SAVE_BITMAP_MEMORY = 0x00000005,
    ANNO_SAVE_JPEG          = 0x00000006,
    ANNO_SAVE_JPEG_MEMORY   = 0x00000007
}AnnoSaveType;

// ----------------------------------------------------------------------------
//	Type used by AnnoBase::GetAnnoBitmapInfo
// ----------------------------------------------------------------------------
typedef struct tagAnnoBitmapInfo
{
    UInt8*			bmData;
    UInt32	        bmFormat;
    UInt32			bmWidth;
    UInt32			bmHeight;
    UInt32          bmPageIndex;
    UInt32          bmPageCount;
    UInt32          bmSize;

    tagAnnoBitmapInfo()
    {
        bmData		= 0;
        bmFormat	= ANNO_BITMAP_FORMAT_NULL;
        bmWidth		= 0;
        bmHeight	= 0;
        bmPageIndex = 0;
        bmPageCount = 0;
        bmSize      = 0;
    }

    void Release()
    {
        if(NULL != bmData)
        {
            delete[] bmData;
            bmData = NULL;
        }

        bmFormat	= ANNO_BITMAP_FORMAT_NULL;
        bmWidth		= 0;
        bmHeight	= 0;
        bmPageIndex = 0;
        bmPageCount = 0;
        bmSize      = 0;
    }
}AnnoBitmapInfo;

typedef struct tagAnnoSaveInfo
{
    Int32 saveState;
    Int32 saveType;
    Int32 savePageNum;
    Int32 shareType;
    bool isAutoSave;
    std::wstring savePath;
    std::wstring saveDirectory;
    void* bitmapDataFormNydus;  //attendee save
    std::vector<int> savePagesList; //all need save pages index
    std::vector<AnnoBitmapInfo> bitmaps; //memory of bitmaps

    tagAnnoSaveInfo()
    {
        saveState = ANNO_SAVE_END;
        saveType = ANNO_SAVE_PNG;
        savePageNum = 0;
        shareType = 0;
        isAutoSave = false;
        bitmapDataFormNydus = NULL;
    }

    void Release()
    {           
        savePagesList.clear();

        for(size_t i=0; i < bitmaps.size(); ++i)
        {
            bitmaps.at(i).Release();
        }
        
        bitmaps.clear();
    }
}AnnoSaveInfo;

typedef enum tagAnnoTranslateType
{
    ANNO_TRANSLATE_NONE                     = 0x0000,
    ANNO_TRANSLATE_WHITEBOARD_TITLE         = 0x0001,   //ZOOM-253664
}AnnoTranslateType;

struct AnnoTranslateInfo
{
    AnnoTranslateType translateType;
    std::wstring      translateText;
};

struct AnnoAndroidJniInfo
{
    long annoWindowJni;
    long annoRenderJni;
    long startbarHeight;
    bool bShareScreen;
    bool bHDpi;

    AnnoAndroidJniInfo()
    {
        annoWindowJni = 0;
        annoRenderJni = 0;
        startbarHeight = 0;
        bShareScreen = false;
        bHDpi = false;
    }
};

#endif // __ANNO_TYPES_H__

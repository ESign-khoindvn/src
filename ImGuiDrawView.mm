#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#import "Esp/CaptainHook.h"
#import "Esp/ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"
#import "Esp/MonoString.h"
#include "Esp/dbdef.h"
#include "1110/patch.h"
#include "1110/haizzz.h"
#import "1110/il2cpp.h"

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale

@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@end

@implementation ImGuiDrawView
#include "1110/hook.h"

static bool show_s0 = false;
static bool MenDeal = true;

///===Get Offset===//
uint64_t namcoi1;
uint64_t namcoi2;
uint64_t addr_PlayerTakeDamage;

// ===== Loading =====
static bool   g_LoadingDone = false;
static double g_LoadingStartTime = 0;

// ===== Auto open menu =====
static bool   g_MenuAutoOpened = false;
static double g_AppStartTime = 0;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device) abort();

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    ImGui::StyleColorsClassic();
    
    io.Fonts->AddFontFromMemoryCompressedTTF((void*)zzz_compressed_data, zzz_compressed_size, 60.0f, NULL, io.Fonts->GetGlyphRangesVietnamese());
    
    ImGui_ImplMetal_Init(_device);
    return self;
}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

- (void)loadView
{
    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;

    // Cử chỉ mở menu: 3 ngón chạm 2 lần
    UITapGestureRecognizer *tap3n2l = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenMenu)];
    tap3n2l.numberOfTapsRequired = 2;
    tap3n2l.numberOfTouchesRequired = 3;
    [self.view addGestureRecognizer:tap3n2l];

    // Cử chỉ đóng menu: 2 ngón chạm 2 lần
    UITapGestureRecognizer *tap2n2l = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCloseMenu)];
    tap2n2l.numberOfTapsRequired = 2;
    tap2n2l.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:tap2n2l];
    
    // Khởi tạo Il2cpp
    Il2CppAttachOld();
    Il2CppMethod methodAccessSystem("Assembly-CSharp.dll");

    addr_PlayerTakeDamage  = methodAccessSystem.getClass("Player", "PlayerDamageBridge").getMethod("ProcessTakeDamage", 1);

    HOOK(addr_PlayerTakeDamage, my_Player_TakeDamage, orig_Player_TakeDamage);
}

// Hàm xử lý cử chỉ
- (void)handleOpenMenu { MenDeal = true; }
- (void)handleCloseMenu { MenDeal = false; }

#pragma mark - Interaction (Logic from file 2.mm)

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    ImGuiIO &io = ImGui::GetIO();
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    ImGuiIO &io = ImGui::GetIO();
    // Nếu không chạm vào Menu, gửi touch cho Game xử lý
    if (!io.WantCaptureMouse) {
        [super touchesBegan:touches withEvent:event];
    }
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    ImGuiIO &io = ImGui::GetIO();
    if (!io.WantCaptureMouse) {
        [super touchesMoved:touches withEvent:event];
    }
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    ImGuiIO &io = ImGui::GetIO();
    if (!io.WantCaptureMouse) {
        [super touchesCancelled:touches withEvent:event];
    }
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    ImGuiIO &io = ImGui::GetIO();
    if (!io.WantCaptureMouse) {
        [super touchesEnded:touches withEvent:event];
    }
    [self updateIOWithTouchEvent:event];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize = ImVec2(view.bounds.size.width, view.bounds.size.height);

    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1.0f / float(view.preferredFramesPerSecond ?: 120);

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    // QUAN TRỌNG: Luôn để YES để nhận được cử chỉ mở Menu khi menu đang đóng
    [self.view setUserInteractionEnabled:YES];

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (!renderPassDescriptor) {
        [commandBuffer commit];
        return;
    }

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder pushDebugGroup:@"ImGui Jane"];

    ImGui_ImplMetal_NewFrame(renderPassDescriptor);
    ImGui::NewFrame();

    // Logic Thời gian & Loading
    if (g_AppStartTime == 0) g_AppStartTime = ImGui::GetTime();
    if (g_LoadingStartTime == 0) g_LoadingStartTime = ImGui::GetTime();

    double loadingElapsed = ImGui::GetTime() - g_LoadingStartTime;
    float loadingProgress = loadingElapsed / 7.0f;

    if (loadingProgress >= 1.0f) {
        loadingProgress = 1.0f;
        g_LoadingDone = true;
    }

    if (!g_MenuAutoOpened && g_LoadingDone) {
        MenDeal = true;
        g_MenuAutoOpened = true;
    }

    // Cấu hình Font và Cửa sổ
    ImFont* font = ImGui::GetFont();
    font->Scale = 15.f / font->FontSize;

    ImVec2 windowSize = ImVec2(340, 220);
    ImVec2 screenSize = io.DisplaySize;
    ImGui::SetNextWindowPos(ImVec2((screenSize.x - windowSize.x) * 0.5f, (screenSize.y - windowSize.y) * 0.5f), ImGuiCond_Appearing);
    ImGui::SetNextWindowSize(windowSize, ImGuiCond_FirstUseEver);

//===Biến công tắc===//
    static bool func_s1 = true;
    static bool func_s2 = true;
    static bool func_s3 = true;
    static bool func_s4 = true;

    static bool func_s1_active = false;
    static bool func_s2_active = false;
    static bool func_s3_active = false;
    static bool func_s4_active = false;
//===================//

    if (MenDeal || !g_LoadingDone)
    {
        ImGui::Begin("Monster Slayer Mod Menu", &MenDeal);

        if (!g_LoadingDone)
        {
            ImGui::Text("Initializing...");
            ImGui::Spacing();
            ImGui::ProgressBar(loadingProgress, ImVec2(-1, 20));
            ImGui::Text("3 Fingers Double Tap - Open Menu");
            ImGui::Text("2 Fingers Double Tap - Close Menu");
        }
        else
        {

            ImGui::Checkbox("God Mode", &gGodMode);
        }
        
        ImGui::End();
    }

            // Logic Patch //
//            if (func_s1 && !func_s1_active) {
//                ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", 0x2D0DBFC, "20008052C0035FD6");
//                Hook1110("Frameworks/UnityFramework.framework/UnityFramework", 0x2D0DBFC, "20008052C0035FD6");
//                func_s1_active = true;
//            }
//            if (!func_s1 && func_s1_active) {
//                DeactiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", 0x2D0DBFC, "20008052C0035FD6");
//                func_s1_active = false;
//            }

    ImGui::Render();
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderEncoder);

    [renderEncoder popDebugGroup];
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {}

@end
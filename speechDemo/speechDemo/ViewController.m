//
//  ViewController.m
//  speechDemo
//
//  Created by zzw on 2018/3/26.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>

@interface ViewController () <AVSpeechSynthesizerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *showSpeechTextF;
@property (weak, nonatomic) IBOutlet UITextField *recognitionTextF;

@property(nonatomic,strong)SFSpeechRecognizer *bufferRec;
@property(nonatomic,strong)SFSpeechAudioBufferRecognitionRequest *bufferRequest;
@property(nonatomic,strong)SFSpeechRecognitionTask *bufferTask;
@property(nonatomic,strong)AVAudioEngine *bufferEngine;
@property(nonatomic,strong)AVAudioInputNode *buffeInputNode;

@property(nonatomic,strong)AVSpeechSynthesizer * speechSynthesizer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //0.0获取权限
    //0.1在info.plist里面配置
    /*
     typedef NS_ENUM(NSInteger, SFSpeechRecognizerAuthorizationStatus) {
     SFSpeechRecognizerAuthorizationStatusNotDetermined,
     SFSpeechRecognizerAuthorizationStatusDenied,
     SFSpeechRecognizerAuthorizationStatusRestricted,
     SFSpeechRecognizerAuthorizationStatusAuthorized,
     };
     */
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                NSLog(@"NotDetermined");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                NSLog(@"Denied");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                NSLog(@"Restricted");
                break;
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                NSLog(@"Authorized");
                break;
            default:
                break;
        }
    }];
    
    
}
- (IBAction)speechClick:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"开始语音识别"]) {
        [sender setTitle:@"停止" forState:UIControlStateNormal];
        
        self.bufferRec = [[SFSpeechRecognizer alloc]initWithLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
        self.bufferEngine = [[AVAudioEngine alloc]init];
        self.buffeInputNode = [self.bufferEngine inputNode];
        
        if (_bufferTask != nil) {
            [_bufferTask cancel];
            _bufferTask = nil;
        }
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
        [audioSession setMode:AVAudioSessionModeMeasurement error:nil];
        [audioSession setActive:true error:nil];
        
        // block外的代码也都是准备工作，参数初始设置等
        self.bufferRequest = [[SFSpeechAudioBufferRecognitionRequest alloc]init];
        self.bufferRequest.shouldReportPartialResults = true;
        __weak ViewController *weakSelf = self;
        self.bufferTask = [self.bufferRec recognitionTaskWithRequest:self.bufferRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            
            if (result != nil) {
                weakSelf.showSpeechTextF.text = result.bestTranscription.formattedString;
            }
            if (error != nil) {
                NSLog(@"%@",error.userInfo);
            }
        }];
        
        // 监听一个标识位并拼接流文件
        AVAudioFormat *format =[self.buffeInputNode outputFormatForBus:0];
        [self.buffeInputNode installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            [weakSelf.bufferRequest appendAudioPCMBuffer:buffer];
        }];
        
        // 准备并启动引擎
        [self.bufferEngine prepare];
        NSError *error = nil;
        if (![self.bufferEngine startAndReturnError:&error]) {
            NSLog(@"%@",error.userInfo);
        };
        
    }else{
        [sender setTitle:@"开始语音识别" forState:UIControlStateNormal];
        [self.bufferEngine stop];
        [self.buffeInputNode removeTapOnBus:0];
        self.bufferRequest = nil;
        self.bufferTask = nil;
    }
    
}

- (IBAction)textRecognitionClick:(id)sender {
    

    AVSpeechUtterance*utterance = [[AVSpeechUtterance alloc]initWithString:self.recognitionTextF.text];//需要转换的文字
    
    utterance.rate=0.5;// 设置语速，范围0-1，注意0最慢，1最快；AVSpeechUtteranceMinimumSpeechRate最慢，AVSpeechUtteranceMaximumSpeechRate最快
    
    AVSpeechSynthesisVoice*voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];//设置发音，这是中文普通话
    
    utterance.voice= voice;
    
    [self.speechSynthesizer speakUtterance:utterance];//开始
    
  
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didStartSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---开始播放");
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---完成播放");
    
}
#pragma mark -- lazy

- (AVSpeechSynthesizer*)speechSynthesizer{
    
    if (!_speechSynthesizer) {
        _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        _speechSynthesizer.delegate = self;
    }
    return _speechSynthesizer;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

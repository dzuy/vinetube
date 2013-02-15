//
//  ViewController.h
//  vine
//
//  Created by Dzuy Linh on 2/7/13.
//  Copyright (c) 2013 Dzuy Linh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequest.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Flurry.h"

@interface ViewController : UIViewController <UITextFieldDelegate, UIGestureRecognizerDelegate,
    UIWebViewDelegate>{
    BOOL is_getting_feed;
    BOOL is_getting_vine;
    BOOL is_showing_credits;
    BOOL is_updating_tags;
    BOOL is_first_load;
    ASIHTTPRequest *http_request;
    NSMutableArray *vines_arr;
    NSMutableArray *channels_arr;
    int active_index;
    MPMoviePlayerController *player;
    MPMoviePlayerController *movie_static;
    
    NSString *search_tag;
    
    int vid_count;
    
    IBOutlet UIView *video_holder;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UITextField *t_input;
    IBOutlet UIImageView *chanel_highlight;
    IBOutlet UILabel *label_tags;
    IBOutlet UIImageView *stati_img_view;
    IBOutlet UIView *credits;
    IBOutlet UILabel *label_credits;
    IBOutlet UIWebView *web_view;
}

- (IBAction) channelHandler:(id)sender;
- (IBAction) channelDownHandler:(id)sender;
- (IBAction) creditsHandler:(id)sender;


@end


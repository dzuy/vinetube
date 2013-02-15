//
//  ViewController.m
//  vine
//
//  Created by Dzuy Linh on 2/7/13.
//  Copyright (c) 2013 Dzuy Linh. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void) initVineTube {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTags) name:@"updateTags" object:nil];
    
    
    is_first_load = true;
    vid_count = 0;
    search_tag = @"";
    label_tags.text = @"newest";
    channels_arr = [[NSMutableArray alloc]initWithObjects:@"", @"cats", @"dogs", @"food", @"blizzard", @"stopmotion", @"howto", @"vineportraits", nil];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.delegate = self;
    [self.view addGestureRecognizer:singleTap];
    [singleTap release];
    
    t_input.delegate = self;
    
    [self updateTags];
    //[self freshSearch];
    [self initStatic];
}
- (void) handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    [t_input resignFirstResponder];
}

- (void) updateTags {
    //NSLog(@"update tags");
    is_updating_tags = true;
    NSString *config_url = @"http://plaidandpin.com/projects/vinetube/tags.json";
    NSURL *url = [NSURL URLWithString:config_url];
    ASIHTTPRequest *tag_request = [ASIHTTPRequest requestWithURL:url];
    [tag_request setDelegate:self];
    [tag_request startAsynchronous];
    [tag_request setTimeOutSeconds:60];
}
- (void) parseTags:(NSDictionary*)dict {
    [Flurry logEvent:@"UPDATE_TAGS"];
    NSArray *valid_arr = [dict objectForKey:@"tags"];

    if ([valid_arr count] > 0) {
        [channels_arr removeAllObjects];
        
        for (int i=0;i<8;i++) {
            NSString *tag = [[[dict objectForKey:@"tags"] objectAtIndex:i] objectForKey:@"tag"];
            [channels_arr addObject:tag];
        }
    }
    
    if (is_first_load) {
        is_first_load = false;
        
        [self freshSearch];
    }
}

- (void) initStatic {
    float playTime = 1.2;
    NSMutableArray *anim_img_arr = [[NSMutableArray alloc] init];
    for (int i=1; i<=25; i++) {
        NSString *img_name = [[NSString alloc] initWithFormat:@"jack-%i.jpg", i];
        [anim_img_arr addObject: [UIImage imageNamed:img_name]];
        [img_name release];
    }
    
    [stati_img_view setImage:[anim_img_arr objectAtIndex:[anim_img_arr count]-1]];
    stati_img_view.animationImages = anim_img_arr;
    stati_img_view.animationDuration = playTime;
    stati_img_view.animationRepeatCount = 0;
    stati_img_view.alpha = 0;
    [stati_img_view startAnimating];
    
    [self showStatic];
}
- (void) showStatic {
    //NSLog(@"show static");
    [self playSound:@"click" ext:@"caf"];
    [self fadeView:stati_img_view alpha:0.8 delay:0];
}
- (void) hideStatic {
    [self fadeView:stati_img_view alpha:0 delay:0];
}


// SEARCH TWEETS WITH VINE.CO
- (void) freshSearch {
    active_index = 0;
    [self getFeedData];
}
- (void) getFeedData {
    [http_request cancel];
    [http_request clearDelegatesAndCancel];
    
    [t_input resignFirstResponder];
    
    is_getting_feed = true;
    is_getting_vine = false;
    
    //NSString *query = [[NSString alloc]initWithFormat:@"vine.co #cats"];    
    NSString *unescaped_string = [[NSString alloc]initWithFormat:@"vine.co #%@", search_tag];
    NSString* escapedUrlString = [unescaped_string stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    //NSLog(@"escapedUrlString: %@", escapedUrlString);
    
    NSString *api_call = [[NSString alloc]initWithFormat:@"http://search.twitter.com/search.json?q=%@", escapedUrlString];
    NSLog(@"getting more: %@", api_call);
    
    NSURL *url = [NSURL URLWithString:api_call];
    http_request = [ASIHTTPRequest requestWithURL:url];
    [http_request setDelegate:self];
    [http_request startAsynchronous];
    [http_request setTimeOutSeconds:60];
    
    [api_call release];
    [unescaped_string release];
}
- (void) parseFeed:(NSDictionary*)feed {    
    NSArray *source = [feed objectForKey:@"results"];
    if ([source count] > 0) {
        int max_vines = [source count];
        if (vines_arr) {
            [vines_arr removeAllObjects];
            vines_arr = nil;
            [vines_arr release];
        }
        vines_arr = [[NSMutableArray alloc]init];
        
        
        for(int i=0;i<max_vines;i++) {
            NSLog(@"feed: %@", [[source objectAtIndex:i] objectForKey:@"text"]);
            
            NSString *sample_tweet = [[source objectAtIndex:i] objectForKey:@"text"];
            NSString *search_str = @"http://t.co/";
            int begin_location = 0;
            NSString *vine_url;
            
            if ([sample_tweet rangeOfString:search_str].location != NSNotFound) {
                begin_location = [sample_tweet rangeOfString:search_str].location;
                vine_url = [sample_tweet substringWithRange:NSMakeRange(begin_location, 20)];
                
                if (i >= 1) {
                    //CHECKS FOR EXISTING VINE
                    
                    BOOL vine_exists = false;
                    for (int j=0; j<[vines_arr count];j++) {
                        if ([vine_url isEqualToString:[vines_arr objectAtIndex:j]]) {
                            vine_exists = true;
                        }
                    }
                    
                    if (!vine_exists) {
                        [vines_arr addObject:vine_url];
                    }
                    
                } else {
                    [vines_arr addObject:vine_url];
                }
                
            
            } else {
                NSLog(@"error: does not contain vine url");
            }
            
        
        }
    } else {
        NSLog(@"no source, try again");
        [self getVine:[vines_arr objectAtIndex: active_index]];
        //[self showFeedLoadError];
    }

    NSLog(@"getFeedData vines_arr: %@", vines_arr);
    [self getVine:[vines_arr objectAtIndex: active_index]];
}

// GET AND PLAY INDIVIDUAL VINE
- (void) parseVinePage:(NSString*)page_source {
    //NSLog(@"page_source: %@", page_source);
    
    // IF ON THE DEVICE, NEED TO GET THE VINE.CO URL AND PARSE AGAIN
    // IF ON SIMULATOR, GO AHEAD AND PARSE AS FOLLOWS    
    NSString *search_noscript_str = @"<noscript>";
    if ([page_source rangeOfString:search_noscript_str].location != NSNotFound) {
        // PAGE USES A REDIRECT
        NSString *search_start_str = @"URL=";
        NSString *search_end_str = @"</noscript>";
        int begin_location = 0;
        int end_location = 0;
        
        // beginning of vine video url
        if ([page_source rangeOfString:search_start_str].location != NSNotFound) {
            begin_location = [page_source rangeOfString:search_start_str].location+4;
        }
        
        // end of vine video url
        if ([page_source rangeOfString:search_end_str].location != NSNotFound) {
            end_location = [page_source rangeOfString:search_end_str].location - 2;
        }
        
        NSString *vine_page_url = [page_source substringWithRange:NSMakeRange(begin_location, (end_location-begin_location))];
        [self getVine:vine_page_url];
    } else {
        NSString *search_start_str = @"property=\"twitter:player:stream\"";
        NSString *search_end_str = @".mp4?versionId=";
        int begin_location = 0;
        int end_location = 0;
        
        // beginning of vine video url
        if ([page_source rangeOfString:search_start_str].location != NSNotFound) {
            begin_location = [page_source rangeOfString:search_start_str].location + 42;
        }
        
        // end of vine video url
        if ([page_source rangeOfString:search_end_str].location != NSNotFound) {
            end_location = [page_source rangeOfString:search_end_str].location + 4;
        }
        
        NSString *vine_video_url = [page_source substringWithRange:NSMakeRange(begin_location, (end_location-begin_location))];
 
        //NSLog(@"page_source: %@", page_source);
        if (!is_showing_credits) {
            [self playVine:vine_video_url];
        }
    }
    
}
- (void) getVine:(NSString*)vine_page_url {
    NSLog(@"IS GETTING VINE: %@", vine_page_url);
    //vine_page_url = @"http://adadasdasasdssssss.com";
    is_getting_vine = true;
    NSURL *url = [NSURL URLWithString:vine_page_url];
    http_request = [ASIHTTPRequest requestWithURL:url];
    [http_request setDelegate:self];
    [http_request startAsynchronous];
    [http_request setTimeOutSeconds:60];
}
- (void) playVine:(NSString*)url {
    //NSLog(@"vine video url: %@", url);
    [spinner startAnimating];
    NSURL *videoURL = [[NSURL alloc] initWithString:url];
  
    if (player) {
        //NSLog(@"REMOVING PREV PLAYER");
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:player];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerLoadStateDidChangeNotification
                                                      object:player];
        
        [player pause];
        player.initialPlaybackTime = -1;
        [player stop];
        player.initialPlaybackTime = -1;
        [player.view removeFromSuperview];
        [player release];
    }
    
    player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
    
    [player prepareToPlay];
    player.movieSourceType = MPMovieSourceTypeStreaming;
    
    [[player view] setFrame:CGRectMake(0, 0, 650, 650)];
    [player view].backgroundColor = [UIColor blackColor];
    
    player.shouldAutoplay = NO;
    player.scalingMode = MPMovieScalingModeNone;
    player.controlStyle = MPMovieControlStyleNone;
    player.backgroundView.backgroundColor = [UIColor blackColor];
    player.repeatMode = MPMovieRepeatModeNone;
    
    //[video_holder addSubview: [player view]];
    [video_holder insertSubview: [player view] atIndex:1];
 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinishedCallback:) name:MPMoviePlayerPlaybackDidFinishNotification object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateChanged:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:player];
    
    [videoURL release];
}

- (void) loadStateChanged:(NSNotification*)aNotification {
    if (player.loadState == 1) {
        [self hideStatic];
    }
    if (player.loadState == 3) {
        [spinner stopAnimating];
        [player play];
        //NSLog(@"total time: %f", player.duration);
    }
}
- (void) movieFinishedCallback:(NSNotification*)aNotification {
    //NSLog(@"FINISHED");
    
    active_index++;
    
    if (active_index == [vines_arr count]) {
        NSLog(@"TIME TO REFRESH");
        [self freshSearch];
    } else {
        [self getVine:[vines_arr objectAtIndex: active_index]];
    }
    
    vid_count++;
    //NSLog(@"vid_count: %i", vid_count);
    
    
    
}

// CHANNELS
- (void) changeChannel:(int)channel {
    [Flurry logEvent:@"CHANGE_CHANNEL"];
    [self showStatic];
    [self hideCredits];
    video_holder.hidden = false;
    search_tag = [channels_arr objectAtIndex:(channel-1)];
    NSString *label_text = [[NSString alloc]initWithFormat:@"#%@", search_tag];
    label_tags.text = label_text;
    [label_text release];
    
    if ([search_tag isEqualToString:@"newest"] || [search_tag isEqualToString:@"Newest"]) {
        
        search_tag = @"";
        label_tags.text = @"newest";
    }
    
    //NSLog(@"search tag: %@", search_tag);
    
    switch (channel) {
        case 1:
            [self setPosition:chanel_highlight posX:768 posY:224];
            break;
        case 2:
            [self setPosition:chanel_highlight posX:825 posY:224];
            break;
        case 3:
            [self setPosition:chanel_highlight posX:882 posY:224];
            break;
        case 4:
            [self setPosition:chanel_highlight posX:939 posY:224];
            break;
        case 5:
            [self setPosition:chanel_highlight posX:768 posY:276];
            break;
        case 6:
            [self setPosition:chanel_highlight posX:825 posY:276];
            break;
        case 7:
            [self setPosition:chanel_highlight posX:882 posY:276];
            break;
        case 8:
            [self setPosition:chanel_highlight posX:939 posY:276];
            break;
            
        default:
            break;
    }
    
    [self freshSearch];
}
- (void) showCredits {
    [self playSound:@"click" ext:@"caf"];
    NSString *urlAddress = @"http://plaidandpin.com/projects/vinetube/vinetube.html";
    NSURL *url = [NSURL URLWithString:urlAddress];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    web_view.delegate = self;
    [web_view loadRequest:requestObj];
    
    is_showing_credits = true;
    [spinner stopAnimating];
    video_holder.hidden = true;
    label_tags.text = @"";
    
    [player pause];
    player.initialPlaybackTime = -1;
    [player stop];
    player.initialPlaybackTime = -1;
    
    [self showStatic];
    credits.hidden = false;
    
    CGRect newFrame = credits.frame;
    newFrame.origin.x = credits.frame.origin.x;
    newFrame.origin.y = 706;
    credits.frame = newFrame;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:12.05];
    [UIView setAnimationDelay:0];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    
    //CGAffineTransform newPos = CGAffineTransformMakeTranslation (posX, posY);
    //view.transform = newPos;
    
    CGRect newFrame2 = credits.frame;
    newFrame2.origin.x = credits.frame.origin.x;
    newFrame2.origin.y = 45;
    credits.frame = newFrame2;
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(hideStatic) withObject:nil afterDelay:1.0];
    
    [self updateTags];
}
- (void) hideCredits {
    is_showing_credits = false;
    credits.hidden = true;
}

// SFX
- (void) playSound:(NSString *)fName ext:(NSString *)ext {
    NSString *path  = [[NSBundle mainBundle] pathForResource : fName ofType :ext];
    if ([[NSFileManager defaultManager] fileExistsAtPath : path]) {
        SystemSoundID audioEffect;
        NSURL *pathURL = [NSURL fileURLWithPath : path];
        AudioServicesCreateSystemSoundID((CFURLRef) pathURL, &audioEffect);
        AudioServicesPlaySystemSound(audioEffect);
    } else {
        NSLog(@"error, file not found: %@", path);
    }
    
    
}

- (IBAction) channelHandler:(id)sender {
    [self changeChannel:[sender tag]];
}
- (IBAction) channelDownHandler:(id)sender {
    [self playSound:@"click" ext:@"caf"];    
}
- (IBAction) creditsHandler:(id)sender {
    if (!is_showing_credits) {
        [self showCredits];
    }
}


#pragma mark - ASI Requests Callbacks
- (void) requestFinished:(ASIHTTPRequest *)request {
    NSError* error;
    NSData *responseData = [request responseData];
    NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    NSString *responseString = [request responseString];
    //SLog(@"response: %@", responseString);
    
    
    if (http_request) {
        http_request = nil;
        [http_request cancel];
        [http_request clearDelegatesAndCancel];
    }
    
    //NSLog(@"request finished");
    if (is_getting_feed) {
        is_getting_feed = false;
        [self parseFeed:responseDict];
    } else if (is_getting_vine) {
        is_getting_vine = false;
        [self parseVinePage:responseString];
        //NSLog(@"response str: %@", responseString);
    } else if (is_updating_tags) {
        is_updating_tags = false;
        [self parseTags:responseDict];
    }
    
}
- (void) requestFailed:(ASIHTTPRequest *)request {
    NSError *error = [request error];
    NSLog(@"FEED REQUEST FAILED: %@", error);
    
    if (is_updating_tags) {
        NSLog(@"is updating tags");
        //[self freshSearch];
    } else {
        //[self changeChannel:0];
        //[self getVine:[vines_arr objectAtIndex: active_index]];
    }
    
    http_request = nil;
    [http_request cancel];
    [http_request clearDelegatesAndCancel];
    
    //[self getFeedData];
    [self showFeedLoadError];
}
- (void) showFeedLoadError{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Looks like we're having\nnetwork connection issues.\n\nLet's try again?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
    [alert show];
    [alert autorelease];
}
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        //NSLog(@"Cancel Tapped.");
    } else if (buttonIndex == 1) {
        [self getFeedData];
    }
}

#pragma mark - Anim Helpers
- (void) fadeView:(UIView*)view alpha:(float)alpha delay:(float)delay{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.5];
    [UIView setAnimationDelay:delay];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    view.alpha = alpha;
    [UIView commitAnimations];
}
- (void) animateView:(UIView*)view posX:(float)posX posY:(float)posY{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelay:0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    
    //CGAffineTransform newPos = CGAffineTransformMakeTranslation (posX, posY);
    //view.transform = newPos;
    
    CGRect newFrame = view.frame;
    newFrame.origin.x = posX;
    newFrame.origin.y = posY;
    view.frame = newFrame;
    
    [UIView commitAnimations];
}
- (void) setPosition:(UIView*)view posX:(int)posX posY:(int)posY {
    CGRect newFrame = view.frame;
    newFrame.origin.x = posX;
    newFrame.origin.y = posY;
    view.frame = newFrame;
}


#pragma mark - TextField Delegate Methods
- (void) textFieldDidBeginEditing:(UITextField *)textField {
    
}
- (BOOL) textFieldShouldReturn:(UITextField *)textField {    
    //[t_input resignFirstResponder];
    return true;
}

#pragma mark - WebView
-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

#pragma mark - View Lifecycle
- (void) viewDidLoad {
    [super viewDidLoad];
    [self initVineTube];
	// Do any additional setup after loading the view, typically from a nib.
}
- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc {
    [spinner release];
    [t_input release];
    [video_holder release];
    [chanel_highlight release];
    [label_tags release];
    [stati_img_view release];
    [credits release];
    [label_credits release];
    [web_view release];
    [super dealloc];
}
- (void) viewDidUnload {
    [spinner release];
    spinner = nil;
    [t_input release];
    t_input = nil;
    [video_holder release];
    video_holder = nil;
    [chanel_highlight release];
    chanel_highlight = nil;
    [label_tags release];
    label_tags = nil;
    [stati_img_view release];
    stati_img_view = nil;
    [credits release];
    credits = nil;
    [label_credits release];
    label_credits = nil;
    [web_view release];
    web_view = nil;
    [super viewDidUnload];
}
@end

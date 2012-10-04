//
//  StartViewController.m
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import "StartViewController.h"
#import "StoryViewController.h"
#import "Story.h"
#import "XMLParser.h"
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "FileInZipInfo.h"

@implementation StartViewController

@synthesize stories;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"navigationbar.jpg"]];
    
    stories = [[NSMutableArray alloc] init];
    
    [self readZippedFiles];
    [self getStoryImages];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)readZippedFiles
{
    NSString *documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDir error:nil];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.iStory'"];
    NSArray *onlyIStories = [dirContents filteredArrayUsingPredicate:filter];
    
    for (NSString *filePath in onlyIStories) {
        ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:[documentsDir stringByAppendingPathComponent:filePath] mode:ZipFileModeUnzip];
        NSArray *infos = [unzipFile listFileInZipInfos];
        for (FileInZipInfo *info in infos) {
            if (![[info.name substringToIndex:1] isEqualToString:@"_"] &&
                ![[info.name substringFromIndex:info.name.length-1] isEqualToString:@"/"] &&
                [[info.name substringFromIndex:info.name.length-3] isEqualToString:@"xml"]) {
                [unzipFile locateFileInZip:info.name];
                
                ZipReadStream *read = [unzipFile readCurrentFileInZip];
                NSMutableData *data = [[NSMutableData alloc] initWithLength:info.length];
                int bytesRead = [read readDataWithBuffer:data];
                
                if (bytesRead > 0)
                    [self parse:data zipFilename:filePath];
                
                [read finishedReading];
            }
        }
        [unzipFile close];
    }
}

- (void)getStoryImages
{
    NSString *documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (Story *story in stories) {
        ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:[documentsDir stringByAppendingPathComponent:story.zipFilename] mode:ZipFileModeUnzip];
        [unzipFile locateFileInZip:story.image];
        FileInZipInfo *info = [unzipFile getCurrentFileInZipInfo];
        
        ZipReadStream *read = [unzipFile readCurrentFileInZip];
        NSMutableData *data = [[NSMutableData alloc] initWithLength:info.length];
        int bytesRead = [read readDataWithBuffer:data];
        
        if (bytesRead > 0) {
            if (![fileManager fileExistsAtPath:[documentsDir stringByAppendingPathComponent:story.name] isDirectory:nil])
                [fileManager createDirectoryAtPath:[documentsDir stringByAppendingPathComponent:story.name] withIntermediateDirectories:YES attributes:nil error:NULL];
            
            [data writeToFile:[[documentsDir stringByAppendingPathComponent:story.name] stringByAppendingPathComponent:story.image] atomically:YES];
        }
    }
    
}

- (void)parse:(NSData *)data zipFilename:(NSString *)zipFilename
{
    NSXMLParser *nsXmlParser = [[NSXMLParser alloc] initWithData:data];
    XMLParser *parser = [[XMLParser alloc] initXMLParser];
    [nsXmlParser setDelegate:parser];
    
    BOOL success = [nsXmlParser parse];
    if (success) {
        parser.story.zipFilename = zipFilename;
        [stories addObject:parser.story];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (stories.count > 0)
        return stories.count/2+1;
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    [cell setSelectionStyle:UITableViewCellEditingStyleNone];
    
    if (stories.count > 0) {
        if (indexPath.row*2 < stories.count) {
            NSString *storyDir = [documentsDir stringByAppendingPathComponent:[[stories objectAtIndex:indexPath.row*2] name]];
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 495, 300)];
            [button setImage:[UIImage imageWithContentsOfFile:[storyDir stringByAppendingPathComponent:[[stories objectAtIndex:indexPath.row*2] valueForKey:@"image"]]] forState:UIControlStateNormal];
            [button setTag:indexPath.row*2];
            [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell addSubview:button];
        }
        if (indexPath.row*2+1 < stories.count) {
            NSString *storyDir = [documentsDir stringByAppendingPathComponent:[[stories objectAtIndex:indexPath.row*2] name]];
            UIButton *button2 = [[UIButton alloc] initWithFrame:CGRectMake(515, 10, 495, 300)];
            [button2 setImage:[UIImage imageWithContentsOfFile:[storyDir stringByAppendingPathComponent:[[stories objectAtIndex:indexPath.row*2+1] valueForKey:@"image"]]] forState:UIControlStateNormal];
            [button2 setTag:indexPath.row*2+1];
            [button2 addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell addSubview:button2];
        }
    }
    
    return cell;
}

- (IBAction)buttonPressed:(id)sender
{
    StoryViewController *storyViewController = [[StoryViewController alloc] init];
    storyViewController.story = [stories objectAtIndex:((UIButton *)sender).tag];
    [self.navigationController pushViewController:storyViewController animated:YES];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"showStory"])
        return NO;
    
    return YES;
}

@end

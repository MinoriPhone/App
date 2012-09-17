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
    
    stories = [[NSMutableArray alloc] init];
    
    [self readZippedFile];
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

- (void)readZippedFile
{
    NSString *documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *iStoryDir = [documentsDir stringByAppendingPathComponent:@"iStory"];
    NSString *filePath = [iStoryDir stringByAppendingPathComponent:@"test.iStory"];
    
    NSLog(@"%@", filePath);
    
    ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:filePath mode:ZipFileModeUnzip];
    NSArray *infos= [unzipFile listFileInZipInfos];
    for (FileInZipInfo *info in infos) {
        if (![[info.name substringToIndex:1] isEqualToString:@"_"] &&
            [[info.name substringFromIndex:info.name.length-3] isEqualToString:@"xml"]) {
            [unzipFile locateFileInZip:info.name];
            
            ZipReadStream *read= [unzipFile readCurrentFileInZip];
            NSMutableData *data= [[NSMutableData alloc] initWithLength:info.length];
            int bytesRead= [read readDataWithBuffer:data];
            
            if (bytesRead > 0)
                [self parse:data];
            
            [read finishedReading];
        }
    }
}

- (void)parse:(NSData *)data
{
    NSXMLParser *nsXmlParser = [[NSXMLParser alloc] initWithData:data];
    XMLParser *parser = [[XMLParser alloc] initXMLParser];
    [nsXmlParser setDelegate:parser];
    
    BOOL success = [nsXmlParser parse];
    if (success) {
        [stories addObject:parser.story];
    } else {
        Log(@"Error parsing document!");
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return stories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.textLabel.text = [[stories objectAtIndex:indexPath.row] name];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"goToStory"]) {
        [segue.destinationViewController setValue:[stories objectAtIndex:[[self.tableView indexPathForSelectedRow] row]] forKey:@"story"];
    }
}

@end

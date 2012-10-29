#import "StartViewController.h"
#import "StoryViewController.h"
#import "XMLParser.h"
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "FileInZipInfo.h"

@implementation StartViewController

@synthesize stories, storyViewController, documentsDir;

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
    documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
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
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (Story *story in stories) {
        if (story.image != nil && ![story.image isEqualToString:@""]) {
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
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        [cell setFrame:CGRectMake(0, 0, tableView.frame.size.width, tableView.rowHeight)];
    }
    
    [cell setSelectionStyle:UITableViewCellEditingStyleNone];
    
    if (stories.count > 0) {
        if (indexPath.row*2 < stories.count) {
            [self createTile:indexPath.row*2 forCell:cell];
        }
        if (indexPath.row*2+1 < stories.count) {
            [self createTile:indexPath.row*2+1 forCell:cell];
        }
    }
    
    return cell;
}

- (void)createTile:(NSInteger)number forCell:(UITableViewCell *)cell
{
    NSInteger width = 495;
    NSInteger height = 300;
    NSInteger x = number%2 == 0 ? 12 : 517;
    NSInteger y = 10;
    
    UIImage *image;
    if ([[stories objectAtIndex:number] valueForKey:@"image"] != nil && ![[[stories objectAtIndex:number] valueForKey:@"image"] isEqualToString:@""]) {
        NSString *storyDir = [documentsDir stringByAppendingPathComponent:[[stories objectAtIndex:number] name]];
        image = [UIImage imageWithContentsOfFile:[storyDir stringByAppendingPathComponent:[[stories objectAtIndex:number] valueForKey:@"image"]]];
    } else {
        image = [UIImage imageNamed:@"defaultStoryImage.png"];
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    if (imageView.frame.size.width > width || imageView.frame.size.height > height) {
        if (((width/imageView.frame.size.width)*imageView.frame.size.height) <= height) {
            NSInteger imageHeight = (width/imageView.frame.size.width)*imageView.frame.size.height;
            imageView.frame = CGRectMake(x, (y+((height-imageHeight)/2)), width, imageHeight);
        } else {
            NSInteger imageWidth = (height/imageView.frame.size.height)*imageView.frame.size.width;
            imageView.frame = CGRectMake((x+((width-imageWidth)/2)), y, imageWidth, height);
        }
    } else {
        imageView.frame = CGRectMake((x+((width-imageView.frame.size.width)/2)), (y+((self.view.frame.size.height-imageView.frame.size.height)/2)), imageView.frame.size.width, imageView.frame.size.height);
    }
    [cell addSubview:imageView];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
    [button setTag:number];
    [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell addSubview:button];
}

- (IBAction)buttonPressed:(id)sender
{
    storyViewController = [[StoryViewController alloc] initWithStory:[stories objectAtIndex:((UIButton *)sender).tag]];
    [self.navigationController pushViewController:storyViewController animated:YES];
}

@end
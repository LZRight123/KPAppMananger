//
//  TestViewController.m
//  Example
//
//  Created by 梁泽 on 2021/8/13.
//

#import "TestViewController.h"
#import "KPAppMananger.h"
@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [KPAppTool installAppWithRemoteURL:@"your ipa url" downloadProgress:nil completion:nil];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//
//  HelloWorldLayer.h
//  test3
//
//  Created by Jose on 5/15/11.
//  Copyright IMT 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "GLES-Render.h"
#import "cocos2d.h"
#import "Box2D.h"
#import "MyContactListener.h"
#import "SimpleAudioEngine.h"
#import <math.h>

#define PTM_RATIO 32


typedef enum {
    LEFT_MOST = 40,
    LEFT = 120,
    RIGHT = 200,
    RIGHT_MOST = 280
} Column;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
    NSMutableArray *enemies;
    CGPoint quetsiLocation; // location of quetsi on game
    CGFloat v;
    int gameSpeed;          // Scrolling speed multiplier of game
    int enemySpeed;         // Scrolling speed multiplier of enemies
    int distanceTraveled;   // distance quetsi has traveled in points
    int quetsiSpeed;        // Speed quetsi moves left/right
    
    // variables used for ease functions
    CGFloat t;
    CGFloat b;
    CGFloat c;
    CGFloat d;
    
    //variables used for touch controls
    CGPoint touchPosition;
    CGPoint firstTouch;
    CGPoint quetsiFirstTouch;
    int fingerVelocity;
    bool fingerDown;
    
    // Box2D ivars
    b2World* world;
    GLESDebugDraw *_debugDraw;
    MyContactListener *_contactListener;
    
    //Finger Position variables
}

- (void)addBoxBodyForSprite:(CCSprite *)sprite;
- (int)convertTouchToColumn:(UITouch *)touch;
- (int)convertUIntToColumn:(uint32_t)x;
- (void) removeDust;
- (NSArray *) getQuestiCollisionNodes;  
- (void) spawnRandomFoodCreature;
- (void) secondUpdate:(ccTime)dt;
- (void) moveToFinger:(ccTime)dt;
- (void) updateQuetsiPosition:(ccTime)dt;
- (CGFloat) easeOutExpo;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end

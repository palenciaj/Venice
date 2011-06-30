//
//  HelloWorldLayer.m
//  test3
//
//  Created by Jose on 5/15/11.
//  Copyright IMT 2011. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "CCTouchDispatcher.h"
#import "CCAtlasNode.h"


CCSprite *quetsi;
CCSpriteBatchNode * quetsiBatchNode;
CCSprite *dust;
CCSpriteBatchNode *dustBatchNode;
CCAnimation *animDust;

CCSprite *background;
CCSprite *background2;

CGSize bgSize;
int vertOffset;


// HelloWorldLayer implementation
@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
        
        //init ivars
        quetsiLocation = ccp(160,420);
        gameSpeed = 300;
        enemySpeed = 50;
        distanceTraveled = 0;
        quetsiSpeed = 200;
        enemies = [[NSMutableArray alloc] init];
        
        // Initialize Box2D World
        b2Vec2 gravity = b2Vec2(0.0f, 0.0f);
        bool doSleep = false;
        world = new b2World(gravity, doSleep);
        // Enable debug draw
        _debugDraw = new GLESDebugDraw( PTM_RATIO * CC_CONTENT_SCALE_FACTOR() );
        world->SetDebugDraw(_debugDraw);
        
        uint32 flags = 0;
        flags += b2DebugDraw::e_shapeBit;
        _debugDraw->SetFlags(flags);
        
        // Create contact listener
        _contactListener = new MyContactListener();
        world->SetContactListener(_contactListener);
        
        // Preload effect
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"hahaha.caf"];

      
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        //create both sprite to handle background
        
        background = [CCSprite spriteWithFile:@"bg1.png"];
        background2 = [CCSprite spriteWithFile:@"bg1.png"];
        [background setVisible:false];
        [background2 setVisible:false];
        
        
        //Get image size
        bgSize = [[background displayedFrame] rect].size;
        
        //vertical offset for background to be flush at the top of the screen
        vertOffset = (bgSize.height - winSize.height) / 2;
        
        //one the screen and second just next to it
        background.position = ccp(winSize.width/2, winSize.height/2 - vertOffset);
        background2.position = ccp(winSize.width/2, background.position.y - bgSize.height + 1);        
        //add schedule to move backgrounds
        [self schedule:@selector(scroll:)];
        
        // add them to main layer
        [self addChild:background];
        [self addChild:background2];
 
      
        
        CCSpriteFrameCache *cache;
        
        // Load sprite frames, which are just a bunch of named rectangle 
        // definitions that go along with the image in a sprite sheet
        cache = [CCSpriteFrameCache sharedSpriteFrameCache];
        [cache addSpriteFramesWithFile:@"quetsi_coordinates.plist" textureFile:@"quetsi_texture.png"];
        //[cache addSpriteFramesWithFile:@"quetsi_coordinates.plist"];
        
        // Load dust text and frames
        [cache addSpriteFramesWithFile:@"dust_coordinates.plist" textureFile:@"dust_texture.png"];

        
        // Create a SpriteSheet -- just a big image which is prepared to 
        // be carved up into smaller images as needed
        quetsiBatchNode = [CCSpriteBatchNode batchNodeWithFile:@"quetsi_texture.png"];
        quetsiBatchNode.position = quetsiLocation;
        [quetsiBatchNode setVisible:false];
        
        
        // Create a spritesheet for dust animation
        dustBatchNode = [CCSpriteBatchNode batchNodeWithFile:@"dust_texture.png"];
        
        // Add sprite sheet to parent (it won't draw anything itself, but 
        // needs to be there so that it's in the rendering pipeline)
        [self addChild:dustBatchNode z:1];
        [self addChild:quetsiBatchNode z:2];
        
        // Create a sprite for the shadow of Quetsi
        //CCSprite *quetsiShadow = [CCSprite spriteWithFile:@"player_shadow.png"];
        //[quetsiBatchNode addChild:quetsiShadow];
        
        // Finally, create a sprite, using the name of a frame in our frame cache.
      
        quetsi = [CCSprite spriteWithSpriteFrameName:@"p1.png"];
        
        //Create sprite for dust, add to its batchnode
        dust = [CCSprite spriteWithSpriteFrameName:@"d1.png"];
        
        // Add the sprite as a child of the sheet, so that it knows where to get its image data.
        [self addBoxBodyForSprite:quetsi];
        [quetsiBatchNode addChild:quetsi z:1 tag:1];
        
        [dustBatchNode addChild:dust];
        
        [dustBatchNode setVisible:false];
        
                
        NSMutableArray *animFrames = [NSMutableArray array];
        NSMutableArray *animDustArray = [NSMutableArray array];
		for(int i = 1; i <=5 ; i++) {
            
			CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"p%01d.png",i]];
            CCSpriteFrame *dustFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"d%01d.png",i]];
            
			[animFrames addObject:frame];
            [animDustArray addObject:dustFrame];
		}
        
        // Create Quetsi Animation object, action and repeate forever
		CCAnimation *animation = [CCAnimation animationWithFrames:animFrames delay:0.1f];
		[quetsi runAction:[CCRepeatForever actionWithAction: [CCAnimate actionWithAnimation:animation restoreOriginalFrame:NO] ]];
        animDust = [CCAnimation animationWithFrames:animDustArray delay:0.05f];
        [animDust retain];

        
        self.isTouchEnabled = YES;
        
        [self schedule:@selector(secondUpdate:) interval:1.0];

	}
	return self;
}

- (void)addBoxBodyForSprite:(CCSprite *)sprite {
    
    b2BodyDef spriteBodyDef;
    spriteBodyDef.type = b2_dynamicBody;
    spriteBodyDef.position.Set(sprite.position.x/PTM_RATIO, 
                               sprite.position.y/PTM_RATIO);
    spriteBodyDef.userData = sprite;
    b2Body *spriteBody = world->CreateBody(&spriteBodyDef);
    
    b2PolygonShape spriteShape;
    spriteShape.SetAsBox(sprite.contentSize.width/PTM_RATIO/2,
                         sprite.contentSize.height/PTM_RATIO/2);
    b2FixtureDef spriteShapeDef;
    spriteShapeDef.shape = &spriteShape;
    spriteShapeDef.density = 10.0;
    spriteShapeDef.isSensor = true;
    spriteBody->CreateFixture(&spriteShapeDef);
    
}

- (void)spriteDone:(id)sender {
    
    CCSprite *sprite = (CCSprite *)sender;
    
    b2Body *spriteBody = NULL;
    for(b2Body *body = world->GetBodyList(); body; body=body->GetNext()) {
        if (body->GetUserData() != NULL) {
            CCSprite *curSprite = (CCSprite *)body->GetUserData();
            if (sprite == curSprite) {
                spriteBody = body;
                break;
            }
        }
    }
    if (spriteBody != NULL) {
        world->DestroyBody(spriteBody);
    }
    
    //[_spriteSheet removeChild:sprite cleanup:YES];
}

- (void)secondUpdate:(ccTime)dt {
    [self spawnRandomFoodCreature];
}

- (void) scroll:(ccTime)dt {
    
    //move them 100*dt pixels to left
    background.position = ccp( background.position.x, background.position.y  + gameSpeed*dt);
    background2.position = ccp( background2.position.x, background2.position.y  + gameSpeed*dt);
    
    //reset position when they are off from view.
    if (background.position.y > 480 + bgSize.height/2) {
        background.position = ccp(160, background2.position.y - bgSize.height + 2);
    }
    else if (background2.position.y > 480 + bgSize.height/2) {
        background2.position = ccp(160, background.position.y - bgSize.height + 2);
    }
    
    //move dust up with map
    dustBatchNode.position = ccp(dustBatchNode.position.x, dustBatchNode.position.y + gameSpeed*dt);
    
    //move enemies up
    NSEnumerator *e = [enemies objectEnumerator];
    while (CCSpriteBatchNode *enemy = (CCSpriteBatchNode* )[e nextObject]) {
        if (enemy.position.y > 520) {
            enemy.position = ccp([self convertUIntToColumn:(arc4random() % 320)], -50);
            continue;
        }
        enemy.position = ccp(enemy.position.x, enemy.position.y + (gameSpeed - enemySpeed) * dt);
    }
    
    // update distance traveled
    distanceTraveled +=  gameSpeed * dt;
    
    // Update our Box2D world
    world->Step(dt, 10, 10);
    for(b2Body *body = world->GetBodyList(); body; body=body->GetNext()) {
        if (body->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *)body->GetUserData();
            CCSpriteBatchNode *batchNode = (CCSpriteBatchNode *)[sprite parent];
            
            b2Vec2 b2Position = b2Vec2((sprite.position.x + batchNode.position.x) /PTM_RATIO,
                                       (sprite.position.y + batchNode.position.y) /PTM_RATIO);
            float32 b2Angle = -1 * CC_DEGREES_TO_RADIANS(sprite.rotation + batchNode.rotation);
            
            body->SetTransform(b2Position, b2Angle);
        }
    }
    
    std::vector<b2Body *>toDestroy; 
    std::vector<MyContact>::iterator pos;
    for(pos = _contactListener->_contacts.begin(); 
        pos != _contactListener->_contacts.end(); ++pos) {
        MyContact contact = *pos;
        
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL) {
            CCSprite *spriteA = (CCSprite *) bodyA->GetUserData();
            CCSprite *spriteB = (CCSprite *) bodyB->GetUserData();
            
            if (spriteA.tag == 1 && spriteB.tag == 2) {
                toDestroy.push_back(bodyB);
            } else if (spriteA.tag == 2 && spriteB.tag == 1) {
                toDestroy.push_back(bodyA);
            } 
        }        
    }
    
    std::vector<b2Body *>::iterator pos2;
    for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
        b2Body *body = *pos2;     
        if (body->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *) body->GetUserData();
            CCSpriteBatchNode *batchNode = (CCSpriteBatchNode *) [sprite parent];
            [batchNode removeChild:sprite cleanup:YES];
            [enemies removeObject:batchNode];
            [self removeChild:batchNode cleanup:YES];
        }
        world->DestroyBody(body);
    }
    
    if (toDestroy.size() > 0) {
        //[[SimpleAudioEngine sharedEngine] playEffect:@"hahaha.caf"];   
    }
}

- (void) moveToFinger:(ccTime)dt {
    if (touchPosition.x > quetsiBatchNode.position.x) {
        quetsiBatchNode.position = ccp((ccTime) quetsiSpeed * dt + quetsiBatchNode.position.x,
                                       quetsiBatchNode.position.y);
    } else {
        quetsiBatchNode.position = ccp(quetsiBatchNode.position.x - (ccTime) quetsiSpeed * dt,
                                       quetsiBatchNode.position.y);
    }
    
    
    //NSLog(@"dt: %f quetsi.x: %f addition:%f", dt, quetsiBatchNode.position.x, (ccTime) quetsiSpeed * dt + quetsiBatchNode.position.x);
}

- (NSArray *) getQuestiCollisionNodes
{

// Check for collision in current lane
    
    NSMutableArray *collisionNodes = [[[NSMutableArray alloc] init] autorelease];
    // Get quetsi Rect
    CGRect quetsiRect = [[quetsiBatchNode getChildByTag:1] boundingBox];    // Must use width/height of animating sprite
    quetsiRect.origin.x += quetsiBatchNode.position.x;                           // use origin of batch node
    quetsiRect.origin.y += quetsiBatchNode.position.y;

    // cycle through enemies
    NSEnumerator *e = [enemies objectEnumerator];
    CCSpriteBatchNode *enemy;
    while ((enemy = (CCSpriteBatchNode* )[e nextObject])) {
        CGRect enemyRect = [[enemy getChildByTag:2] boundingBox];
        enemyRect.origin.x += enemy.position.x;
        enemyRect.origin.y += enemy.position.y;
        
        if (CGRectIntersectsRect(enemyRect, quetsiRect)) {
            // If collision has happened, return node quetsi has collided with
            [collisionNodes addObject:enemy];
        }
    }
    
    return collisionNodes;
}

- (void) spawnRandomFoodCreature {
    // Create Red Treat Sprite Sheet
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"red_coordinates.plist" textureFile:@"red_texture.png"];
    CCSpriteBatchNode *redBatchNode = [CCSpriteBatchNode batchNodeWithFile:@"red_texture.png"];
    [redBatchNode setVisible: false];
    
    
    // Set Red Treat Sheet position, randomly pick a lane
    redBatchNode.position = ccp([self convertUIntToColumn:(arc4random() % 320)], -50);
    
    // Create red animated sprite
    CCSprite *red = [CCSprite spriteWithSpriteFrameName:@"r1.png"];
    red.tag = 2;
    
    // Create enemy animation frame array
    NSMutableArray *animRedArray = [NSMutableArray array];
    for(int i = 1; i <=5 ; i++) {
        CCSpriteFrame *redFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"r%01d.png",i]];
        [animRedArray addObject:redFrame];
    }

    // Create Red Animation object, action and repeate forever
    CCAnimation *redAnimation = [CCAnimation animationWithFrames:animRedArray delay:0.1f];
    [red runAction:[CCRepeatForever actionWithAction: [CCAnimate actionWithAnimation:redAnimation restoreOriginalFrame:NO] ]];
    
    // Add sprite sheet to parent (it won't draw anything itself, but 
    // needs to be there so that it's in the rendering pipeline)
    [self addBoxBodyForSprite:red];
    [redBatchNode addChild:red];
    [self addChild:redBatchNode z:1 tag:2];
    [enemies addObject:redBatchNode];
}

- (int)convertTouchToColumn:(UITouch *)touch {
    return  (int) ((int)[self convertTouchToNodeSpace:touch].x )/ 80 * 80  + 40;
}

- (int)convertUIntToColumn:(uint32_t)x {
    return (int) x / 80 * 80 + 40;
}

//Handle touch
-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

//initi touch handling function
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    //if same column, don't do anything
    //if (quetsiLocation.x == [self convertTouchToColumn:touch])
    //    return YES;
    
    //[self scheduleUpdateWithPriority:-10];
    
    //save quetsi position prior to touch
    dustBatchNode.position = quetsiLocation;
    dustBatchNode.position.y -= 6;
    
    touchPosition.x = [self convertTouchToNodeSpace:touch].x;
    touchPosition.y = 420;
    //quetsiLocation.x = [self convertTouchToColumn:touch];
    //quetsiLocation.y = 420;
    
    [quetsiBatchNode stopAllActions];
    //id moveaction = [CCMoveTo actionWithDuration:.2 position:quetsiLocation];
    //id easeout = [CCEaseExponentialOut actionWithAction:moveaction];
    
    // perform dust animation
    
    //[dustBatchNode setVisible:true];
    
    //id actionDustAnim = [CCAnimate actionWithAnimation:animDust restoreOriginalFrame:NO];
    //id actionEndDustFunc = [CCCallFunc actionWithTarget:self selector:@selector(removeDust)];
    
    //id actionSequence = [CCSequence actions: actionDustAnim, actionEndDustFunc, nil];
    
    //[dust runAction:actionSequence];
    //[quetsiBatchNode runAction: easeout];
    [self schedule:@selector(moveToFinger:)];
    
    return YES;
}

// call back function for dust anim sequence

- (void) removeDust {
    [dustBatchNode setVisible:false];
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {

    //if same column, don't do anything
    //if (quetsiLocation.x == [self convertTouchToColumn:touch])
    //    return;
    
    // remove previous dust
    [self removeDust];
    
    // save quetsi position on dust prior to touch
    dustBatchNode.position = quetsiLocation;
    
    touchPosition.x = [self convertTouchToNodeSpace:touch].x;
    touchPosition.y = 420;
    //quetsiLocation.x = [self convertTouchToColumn:touch];
    
    //[quetsiBatchNode stopAllActions];
    //id moveaction = [CCMoveTo actionWithDuration:.2 position:quetsiLocation];
    //id easeout = [CCEaseExponentialOut actionWithAction:moveaction];
    
    // perform dust animation
    [dustBatchNode setVisible:true];
    
    id actionDustAnim = [CCAnimate actionWithAnimation:animDust];
    id actionEndDustFunc = [CCCallFunc actionWithTarget:self selector:@selector(removeDust)];
    
    id actionSequence = [CCSequence actions: actionDustAnim, actionEndDustFunc, nil];
    
    [dust runAction:actionSequence];
    //[quetsiBatchNode runAction: easeout];
}

//end touch handling function
- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    //quetsiLocation.x = [self convertToColumn:touch];
    //quetsiLocation.y = 420;
    
    //[quetsiBatchNode stopAllActions];
    //id moveaction = [CCMoveTo actionWithDuration:.1 position:quetsiLocation];
    //id easeout = [CCEaseExponentialOut actionWithAction:moveaction];
    
    //[quetsiBatchNode runAction: easeout];
    
    //[self unscheduleUpdate];
    [self unschedule:@selector(moveToFinger:)];
}



-(void) update:(ccTime)deltaTime
{
    //quetsi.position = quetsiLocation;
    //[quetsi stopAllActions];
//    [quetsi runAction: [CCMoveTo actionWithDuration:.1 position:quetsiLocation]];
    // update your node here
    // DON'T draw it, JUST update it.
    
    // example:
    //rotation_ = value * deltaTime;
   // NSLog(@"Quetsi Location %f", quetsiBatchNode.position.x);
}

-(void) draw
{
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
	world->DrawDebugData();
    
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);	
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
    [animDust release];
    [enemies release];
    delete world;
    delete _debugDraw;
    delete _contactListener;
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end

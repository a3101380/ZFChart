//
//  ZFXAxisLine.m
//  ZFChartView
//
//  Created by apple on 16/3/14.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "ZFXAxisLine.h"
#import "ZFConst.h"

@interface ZFXAxisLine()

/** 定时器 */
@property (nonatomic, strong) NSTimer * timer;

/** 动画时间 */
@property (nonatomic, assign) CGFloat animationDuration;
/** 箭头边长 */
@property (nonatomic, assign) CGFloat arrowsWidth;
/** 箭头边长的一半 */
@property (nonatomic, assign) CGFloat arrowsWidthHalf;
/** 坐标轴线宽的一半 */
@property (nonatomic, assign) CGFloat lineWidthHalf;

@end

@implementation ZFXAxisLine

/**
 *  初始化默认变量
 */
- (void)commonInit{
    _xLineWidth = self.frame.size.width - ZFAxisLineStartXPos - 20.f;
    _xLineHeight = 1.f;
    
    _xLineStartXPos = ZFAxisLineStartXPos;
    _xLineStartYPos = self.frame.size.height * EndRatio;
    _xLineEndXPos = self.frame.size.width - 20;
    _xLineEndYPos = _xLineStartYPos;
    
    _animationDuration = 0.5f;
    _arrowsWidth = 10.f;
    _arrowsWidthHalf = _arrowsWidth / 2.f;
    _lineWidthHalf = _xLineHeight / 2.f;
    _axisColor = ZFBlack;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark - 坐标轴

/**
 *  坐标轴起始位置（未填充）
 *
 *  @return UIBezierPath
 */
- (UIBezierPath *)axisLineNoFill{
    UIBezierPath * bezier = [UIBezierPath bezierPathWithRect:CGRectMake(_xLineStartXPos, _xLineStartYPos, _xLineHeight, _xLineHeight)];
    [bezier stroke];
    return bezier;
}

/**
 *  画x轴
 *
 *  @return UIBezierPath
 */
- (UIBezierPath *)drawXAxisLine{
    UIBezierPath * bezier = [UIBezierPath bezierPathWithRect:CGRectMake(_xLineStartXPos, _xLineStartYPos, _xLineWidth, _xLineHeight)];
    [bezier stroke];
    return bezier;
}

/**
 *  x轴shapeLayer
 *
 *  @return CAShapeLayer
 */
- (CAShapeLayer *)xAxisLineShapeLayer{
    CAShapeLayer * xAxisLineLayer = [CAShapeLayer layer];
    xAxisLineLayer.fillColor = _axisColor.CGColor;
    xAxisLineLayer.path = [self drawXAxisLine].CGPath;
    
    if (_isAnimated) {
        CABasicAnimation * animation = [self animationFromValue:[self axisLineNoFill] toValue:[self drawXAxisLine]];
        [xAxisLineLayer addAnimation:animation forKey:nil];
    }
    
    return xAxisLineLayer;
}

#pragma mark - 箭头

/**
 *  箭头起始位置（未填充）
 *
 *  @return UIBezierPath
 */
- (UIBezierPath *)arrowsNoFill{
    UIBezierPath * bezier = [UIBezierPath bezierPath];
    [bezier moveToPoint:CGPointMake(_xLineStartXPos + _xLineWidth, _xLineEndYPos + _arrowsWidthHalf + _lineWidthHalf)];
    [bezier addLineToPoint:CGPointMake(_xLineStartXPos + _xLineWidth, _xLineEndYPos - _arrowsWidthHalf + _lineWidthHalf)];
    [bezier stroke];
    
    return bezier;
}

/**
 *  画箭头
 *
 *  @return UIBezierPath
 */
- (UIBezierPath *)drawArrows{
    UIBezierPath * bezier = [UIBezierPath bezierPath];
    [bezier moveToPoint:CGPointMake(_xLineEndXPos, _xLineEndYPos - _arrowsWidthHalf + _lineWidthHalf)];
    [bezier addLineToPoint:CGPointMake(_xLineEndXPos + _arrowsWidthHalf * ZFTan(60), _xLineEndYPos + _lineWidthHalf)];
    [bezier addLineToPoint:CGPointMake(_xLineEndXPos, _xLineEndYPos + _arrowsWidthHalf + _lineWidthHalf)];
    [bezier closePath];
    [bezier fill];
    
    return bezier;
}

/**
 *  箭头CAShapeLayer
 *
 *  @return CAShapeLayer
 */
- (CAShapeLayer *)arrowsShapeLayer{
    CAShapeLayer * arrowsLayer = [CAShapeLayer layer];
    arrowsLayer.fillColor = _axisColor.CGColor;
    arrowsLayer.path = [self drawArrows].CGPath;
    
    if (_isAnimated) {
        CABasicAnimation * animation = [self animationFromValue:[self arrowsNoFill] toValue:[self drawArrows]];
        [arrowsLayer addAnimation:animation forKey:nil];
    }
    
    return arrowsLayer;
}

#pragma mark - 动画

/**
 *  填充动画
 *
 *  @return CABasicAnimation
 */
- (CABasicAnimation *)animationFromValue:(UIBezierPath *)fromValue toValue:(UIBezierPath *)toValue{
    CABasicAnimation * fillAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    fillAnimation.duration = _animationDuration;
    fillAnimation.fillMode = kCAFillModeForwards;
    fillAnimation.removedOnCompletion = NO;
    fillAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    fillAnimation.fromValue = (id)fromValue.CGPath;
    fillAnimation.toValue = (id)toValue.CGPath;
    
    return fillAnimation;
}

/**
 *  清除之前所有subLayers
 */
- (void)removeAllSubLayers{
    NSArray * sublayers = [NSArray arrayWithArray:self.layer.sublayers];
    for (CALayer * layer in sublayers) {
        [layer removeAllAnimations];
        [layer removeFromSuperlayer];
    }
}

#pragma mark - public method

/**
 *  重绘
 */
- (void)strokePath{
    [self removeAllSubLayers];
    [self.layer addSublayer:[self xAxisLineShapeLayer]];
    
    //有动画时,延迟0.5秒执行
    if (_isAnimated) {
        self.timer = [NSTimer timerWithTimeInterval:_animationDuration target:self selector:@selector(timerAction:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    }else{
        [self.layer addSublayer:[self arrowsShapeLayer]];
    }
}

#pragma mark - 定时器

- (void)timerAction:(NSTimer *)sender{
    [self.layer addSublayer:[self arrowsShapeLayer]];
    
    [sender invalidate];
    sender = nil;
}

#pragma mark - 重写setter,getter方法

- (void)setXLineWidth:(CGFloat)xLineWidth{
    if (xLineWidth < self.frame.size.width - ZFAxisLineStartXPos - 20.f) {
        _xLineWidth = self.frame.size.width - ZFAxisLineStartXPos - 20.f;
    }else{
        _xLineWidth = xLineWidth;
        _xLineEndXPos = _xLineStartXPos + _xLineWidth;
    }
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, _xLineEndXPos + 20.f, self.frame.size.height);
}

@end

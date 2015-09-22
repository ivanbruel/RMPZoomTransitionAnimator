//  Copyright (c) 2015 Recruit Marketing Partners Co.,Ltd. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "RMPZoomTransitionAnimator.h"

@interface RMPZoomTransitionAnimator ()

@property (nonatomic, strong) void (^completion)(void);

@end

@implementation RMPZoomTransitionAnimator

// constants for transition animation
static const NSTimeInterval kForwardAnimationDuration         = 0.3;
static const NSTimeInterval kForwardCompleteAnimationDuration = 0.2;
static const NSTimeInterval kBackwardAnimationDuration         = 0.25;
static const NSTimeInterval kBackwardCompleteAnimationDuration = 0.18;

#pragma mark - <UIViewControllerAnimatedTransitioning>

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
  if (self.goingForward) {
    return kForwardAnimationDuration + kForwardCompleteAnimationDuration;
  } else {
    return kBackwardAnimationDuration + kBackwardCompleteAnimationDuration;
  }
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
  // Setup for animation transition
  UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  UIViewController *toVC   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  UIView *containerView    = [transitionContext containerView];
  [containerView addSubview:fromVC.view];
  [containerView addSubview:toVC.view];
  
  // Without animation when you have not confirm the protocol
  Protocol *animating = @protocol(RMPZoomTransitionAnimating);
  BOOL doesNotConfirmProtocol = ![self.sourceTransition conformsToProtocol:animating] || ![self.destinationTransition conformsToProtocol:animating];
  if (doesNotConfirmProtocol) {
    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    return;
  }
  
  // Add a alphaView To be overexposed, so background becomes dark in animation
  UIView *alphaView = [[UIView alloc] initWithFrame:[transitionContext finalFrameForViewController:toVC]];
  alphaView.backgroundColor = [self.sourceTransition transitionSourceBackgroundColor];
  [containerView addSubview:alphaView];
  
  // Transition source of image to move me to add to the last
  UIImageView *sourceImageView = [self.sourceTransition transitionSourceImageView];
  [containerView addSubview:sourceImageView];
  
  
  if (self.goingForward) {
    CGRect destinationFrame = [self.destinationTransition transitionDestinationImageViewFrame];
    BOOL sourceIsRounded = [self.sourceTransition transitionDestinationImageViewIsRounded];
    BOOL destinationIsRounded = [self.destinationTransition transitionDestinationImageViewIsRounded];
    if (sourceIsRounded) {
      [self animateImageView:sourceImageView fromCornerRadius:sourceImageView.layer.cornerRadius toCornerRadius:destinationFrame.size.height/2 duration:kForwardAnimationDuration animationCurve:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] completion:^{
        CGFloat destinationCornerRadius = destinationIsRounded ? destinationFrame.size.height / 2.0 : 0;
        [self animateImageView:sourceImageView fromCornerRadius:sourceImageView.layer.cornerRadius toCornerRadius:destinationCornerRadius duration:kForwardCompleteAnimationDuration animationCurve:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] completion:nil];
      }];
    } else {
      CGFloat destinationCornerRadius = destinationIsRounded ? destinationFrame.size.height / 2.0 : 0;
      [self animateImageView:sourceImageView fromCornerRadius:sourceImageView.layer.cornerRadius toCornerRadius:destinationCornerRadius duration:kForwardCompleteAnimationDuration animationCurve:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] completion:nil];
    }
    [UIView animateWithDuration:kForwardAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       sourceImageView.frame = destinationFrame;
                       alphaView.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                       [UIView animateWithDuration:kForwardCompleteAnimationDuration
                                             delay:0
                                           options:UIViewAnimationOptionCurveEaseOut
                                        animations:^{
                                          alphaView.alpha = 0;
                                        }
                                        completion:^(BOOL finished) {
                                          sourceImageView.alpha = 0;
                                          if ([self.destinationTransition conformsToProtocol:@protocol(RMPZoomTransitionAnimating)] &&
                                              [self.destinationTransition respondsToSelector:@selector(zoomTransitionAnimator:didCompleteTransition:animatingSourceImageView:)]) {
                                            [self.destinationTransition zoomTransitionAnimator:self
                                                                         didCompleteTransition:![transitionContext transitionWasCancelled]
                                                                      animatingSourceImageView:sourceImageView];
                                          }
                                          [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                                        }];
                     }];
    
  } else {
    CGRect destinationFrame = [self.destinationTransition transitionDestinationImageViewFrame];
    BOOL sourceIsRounded = [self.sourceTransition transitionDestinationImageViewIsRounded];
    BOOL destinationIsRounded = [self.destinationTransition transitionDestinationImageViewIsRounded];
    if (destinationIsRounded) {
      [self animateImageView:sourceImageView fromCornerRadius:sourceImageView.layer.cornerRadius toCornerRadius:destinationFrame.size.height/2 duration:kBackwardAnimationDuration animationCurve:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] completion:^{
        CGFloat destinationCornerRadius = destinationIsRounded ? destinationFrame.size.height / 2.0 : 0;
        [self animateImageView:sourceImageView fromCornerRadius:sourceImageView.layer.cornerRadius toCornerRadius:destinationCornerRadius duration:kBackwardCompleteAnimationDuration animationCurve:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] completion:nil];
      }];
    } else {
      CGFloat destinationCornerRadius = destinationIsRounded ? destinationFrame.size.height / 2.0 : 0;
      [self animateImageView:sourceImageView fromCornerRadius:sourceImageView.layer.cornerRadius toCornerRadius:destinationCornerRadius duration:kBackwardCompleteAnimationDuration animationCurve:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] completion:nil];
    }
    [UIView animateWithDuration:kBackwardAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       sourceImageView.frame = destinationFrame;
                       alphaView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                       [UIView animateWithDuration:kBackwardCompleteAnimationDuration
                                             delay:0
                                           options:UIViewAnimationOptionCurveEaseOut
                                        animations:^{
                                          sourceImageView.alpha = 0;
                                        }
                                        completion:^(BOOL finished) {
                                          if ([self.destinationTransition conformsToProtocol:@protocol(RMPZoomTransitionAnimating)] &&
                                              [self.destinationTransition respondsToSelector:@selector(zoomTransitionAnimator:didCompleteTransition:animatingSourceImageView:)]) {
                                            [self.destinationTransition zoomTransitionAnimator:self
                                                                         didCompleteTransition:![transitionContext transitionWasCancelled]
                                                                      animatingSourceImageView:sourceImageView];
                                          }
                                          [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                                        }];
                     }];
  }
}

- (void)animateImageView:(UIImageView *)imageView fromCornerRadius:(CGFloat)fromCornerRadius toCornerRadius:(CGFloat)toCornerRadius duration:(CGFloat)duration animationCurve:(CAMediaTimingFunction *)animationCurve completion:(void(^)(void))completion {
  self.completion = completion;
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
  animation.timingFunction = [CAMediaTimingFunction     functionWithName:kCAMediaTimingFunctionLinear];
  animation.fromValue = [NSNumber numberWithFloat:fromCornerRadius];
  animation.toValue = [NSNumber numberWithFloat:toCornerRadius];
  animation.timingFunction = animationCurve;
  animation.duration = duration;
  animation.delegate = self;
  [imageView.layer addAnimation:animation forKey:@"cornerRadius"];
  [imageView.layer setCornerRadius:toCornerRadius];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
  if (self.completion) {
    self.completion();
  }
}

@end

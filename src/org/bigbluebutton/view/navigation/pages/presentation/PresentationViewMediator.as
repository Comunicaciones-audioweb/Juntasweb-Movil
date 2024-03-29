package org.bigbluebutton.view.navigation.pages.presentation {
	
	import flash.display.DisplayObject;
	import flash.events.TransformGestureEvent;
	import mx.core.FlexGlobals;
	import org.bigbluebutton.command.LoadSlideSignal;
	import org.bigbluebutton.core.IPresentationService;
	import org.bigbluebutton.model.IUserSession;
	import org.bigbluebutton.model.presentation.Presentation;
	import org.bigbluebutton.model.presentation.Slide;
	import robotlegs.bender.bundles.mvcs.Mediator;
	
	public class PresentationViewMediator extends Mediator {
		
		[Inject]
		public var view:IPresentationView;
		
		[Inject]
		public var userSession:IUserSession;
		
		[Inject]
		public var loadSlideSignal:LoadSlideSignal;
		
		[Inject]
		public var presentationService:IPresentationService;
		
		private var _currentPresentation:Presentation;
		
		private var _currentSlideNum:int = -1;
		
		private var _currentSlide:Slide;
		
		override public function initialize():void {
			userSession.presentationList.presentationChangeSignal.add(presentationChangeHandler);
			view.slide.addEventListener(TransformGestureEvent.GESTURE_SWIPE, swipehandler);
			setPresentation(userSession.presentationList.currentPresentation);
			FlexGlobals.topLevelApplication.backBtn.visible = false;
			FlexGlobals.topLevelApplication.profileBtn.visible = true;
		}
		
		private function swipehandler(e:TransformGestureEvent):void {
			if (userSession.userList.me.presenter) {
				if (e.offsetX == -1 && _currentSlideNum < _currentPresentation.slides.length - 1) {
					setCurrentSlideNum(_currentSlideNum + 1);
					presentationService.gotoSlide(_currentPresentation.id + "/" + _currentSlide.slideNumber);
				} else if (e.offsetX == 1 && _currentSlideNum > 0) {
					trace("current slide : " + _currentSlideNum);
					setCurrentSlideNum(_currentSlideNum - 1);
					presentationService.gotoSlide(_currentPresentation.id + "/" + _currentSlide.slideNumber);
				}
			}
		}
		
		private function displaySlide():void {
			if (_currentSlide != null) {
				_currentSlide.slideLoadedSignal.remove(slideLoadedHandler);
			}
			if (_currentPresentation != null && _currentSlideNum >= 0) {
				_currentSlide = _currentPresentation.getSlideAt(_currentSlideNum);
				if (_currentSlide != null) {
					if (_currentSlide.loaded && view != null) {
						view.setSlide(_currentSlide);
					} else {
						_currentSlide.slideLoadedSignal.add(slideLoadedHandler);
						loadSlideSignal.dispatch(_currentSlide);
					}
				}
			} else if (view != null) {
				view.setSlide(null);
			}
		}
		
		private function presentationChangeHandler():void {
			setPresentation(userSession.presentationList.currentPresentation);
		}
		
		private function slideChangeHandler():void {
			setCurrentSlideNum(_currentPresentation.currentSlideNum);
		}
		
		private function setPresentation(p:Presentation):void {
			if (_currentPresentation != null) {
				_currentPresentation.slideChangeSignal.remove(slideChangeHandler);
			}
			_currentPresentation = p;
			if (_currentPresentation != null) {
				view.setPresentationName(_currentPresentation.fileName);
				_currentPresentation.slideChangeSignal.add(slideChangeHandler);
				setCurrentSlideNum(p.currentSlideNum);
			} else {
				view.setPresentationName("");
			}
		}
		
		private function setCurrentSlideNum(n:int):void {
			_currentSlideNum = n;
			displaySlide();
		}
		
		private function slideLoadedHandler():void {
			displaySlide();
		}
		
		override public function destroy():void {
			userSession.presentationList.presentationChangeSignal.remove(presentationChangeHandler);
			if (_currentPresentation != null) {
				_currentPresentation.slideChangeSignal.remove(slideChangeHandler);
			}
			super.destroy();
			view.dispose();
			view = null;
		}
	}
}

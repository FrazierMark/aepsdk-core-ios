/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */
#if os(iOS)
    @testable import AEPServices
    @testable import AEPServicesMocks
    import Foundation
    import UIKit
    import WebKit
    import XCTest

    @available(iOSApplicationExtension, unavailable)
    class FullscreenMessageTests : XCTestCase {
        let mockHtml = "somehtml"
        var fullscreenMessage : FullscreenMessage?
        var expectation: XCTestExpectation?
        var webViewExpectation: XCTestExpectation?
        var webViewContent: String?
        var mockUIService: UIService?

        var rootViewController: UIViewController!

        var messageMonitor: MessageMonitor!
        var mockMessageSettings: MessageSettings!
        var mockFullscreenListener: MockFullscreenListener!
        var mockMessagingDelegate: MockMessagingDelegate!
        var handler: ((Any?) -> Void)!
        var handlerCalled = false
        var handlerContent: Any? = nil

        override func setUp() {
            messageMonitor = MessageMonitor()
            mockFullscreenListener = MockFullscreenListener()
            mockMessagingDelegate = MockMessagingDelegate()
            mockMessageSettings = MessageSettings()
        
            ServiceProvider.shared.messagingDelegate = mockMessagingDelegate
            fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: mockFullscreenListener, isLocalImageUsed: false, messageMonitor: messageMonitor, settings: mockMessageSettings)
            mockUIService = MockUIService()
            ServiceProvider.shared.uiService = mockUIService!
                
            handler = { content in
                self.handlerCalled = true
                self.handlerContent = content
                self.expectation?.fulfill()
            }
        }

        func test_init_whenListenerIsNil() {
            fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: nil, isLocalImageUsed: false, messageMonitor: messageMonitor)
            XCTAssertNotNil(fullscreenMessage)
        }

        func test_init_whenIsLocalImageTrue() {
            fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener(), isLocalImageUsed: true, messageMonitor: messageMonitor)
            XCTAssertNotNil(fullscreenMessage)
        }

        func test_init_whenIsLocalImageFalse() {
            fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener(), isLocalImageUsed: false, messageMonitor: messageMonitor)
            XCTAssertNotNil(fullscreenMessage)
        }

        func testDismiss() {
            expectation = XCTestExpectation(description: "Testing Dismiss FullscreenMessage")
            mockFullscreenListener.setExpectation(expectation!)
            messageMonitor.displayMessage()
            fullscreenMessage?.dismiss()
            wait(for: [expectation!], timeout: 2.0)
            XCTAssertTrue(mockFullscreenListener.onDismissCalled)
            XCTAssertTrue(mockMessagingDelegate.onDismissCalled)
        }
    
        func testDismissNoMessageVisible() {
            expectation = XCTestExpectation(description: "Testing Dismiss FullscreenMessage")
            expectation?.isInverted = true
            mockFullscreenListener.setExpectation(expectation!)
            fullscreenMessage?.dismiss()
            wait(for: [expectation!], timeout: 1.0)
            XCTAssertFalse(mockFullscreenListener.onDismissCalled)
            XCTAssertFalse(mockMessagingDelegate.onDismissCalled)
        }

        func testShow() {
            expectation = XCTestExpectation(description: "Testing Show FullscreenMessage")
            mockFullscreenListener.setExpectation(expectation!)
            fullscreenMessage?.scriptHandlers["testScript"] = handler
            messageMonitor.dismissMessage()
            fullscreenMessage?.show()
            wait(for: [expectation!], timeout: 2.0)
            XCTAssertTrue(mockFullscreenListener.onShowCalled)
            XCTAssertTrue(mockMessagingDelegate.shouldShowMessageCalled)
            XCTAssertTrue(mockMessagingDelegate.onShowCalled)
        }
    
        func testShowWithUITakeover() {
            expectation = XCTestExpectation(description: "Testing Show FullscreenMessage")
            mockFullscreenListener.setExpectation(expectation!)
            mockMessageSettings.setUiTakeover(true)
            mockMessageSettings.setBackdropColor("000000")
            mockMessageSettings.setBackdropOpacity(0.3)
            fullscreenMessage?.show()
            wait(for: [expectation!], timeout: 2.0)
            XCTAssertTrue(mockFullscreenListener.onShowCalled)
            XCTAssertTrue(mockMessagingDelegate.shouldShowMessageCalled)
            XCTAssertTrue(mockMessagingDelegate.onShowCalled)
            XCTAssertNotNil(fullscreenMessage?.transparentBackgroundView)
            XCTAssertEqual(fullscreenMessage?.transparentBackgroundView?.backgroundColor, mockMessageSettings.getBackgroundColor())
            let webview = fullscreenMessage?.webView as? WKWebView
            XCTAssertEqual(0.0, webview?.scrollView.layer.cornerRadius)
        }
    
        func testShowWithCornerRadius() {
            expectation = XCTestExpectation(description: "Testing Show FullscreenMessage")
            mockFullscreenListener.setExpectation(expectation!)
            mockMessageSettings.setCornerRadius(15.0)
            fullscreenMessage?.show()
            wait(for: [expectation!], timeout: 2.0)
            XCTAssertTrue(mockFullscreenListener.onShowCalled)
            XCTAssertTrue(mockMessagingDelegate.shouldShowMessageCalled)
            XCTAssertTrue(mockMessagingDelegate.onShowCalled)
            let webview = fullscreenMessage?.webView as? WKWebView
            XCTAssertEqual(15.0, webview?.scrollView.layer.cornerRadius)
        }
    
        func testShowWithPayloadUsingLocalAssets() throws {
            expectation = XCTestExpectation(description: "Testing Show FullscreenMessage")
            mockFullscreenListener.setExpectation(expectation!)
            fullscreenMessage?.scriptHandlers["testScript"] = handler
            fullscreenMessage?.isLocalImageUsed = true
            fullscreenMessage?.payloadUsingLocalAssets = "use me instead"
            messageMonitor.dismissMessage()
            fullscreenMessage?.show()
            wait(for: [expectation!], timeout: 2.0)
            XCTAssertTrue(mockFullscreenListener.onShowCalled)
            XCTAssertTrue(mockMessagingDelegate.shouldShowMessageCalled)
            XCTAssertTrue(mockMessagingDelegate.onShowCalled)
        }
    
        func testShowWithGestures() {
            expectation = XCTestExpectation(description: "Testing Show FullscreenMessage")
            mockFullscreenListener.setExpectation(expectation!)
            mockMessageSettings.setGestures([
                .swipeUp: URL(string: "https://adobe.com")!
            ])
            fullscreenMessage?.show()
            wait(for: [expectation!], timeout: 2.0)
            XCTAssertTrue(mockFullscreenListener.onShowCalled)
            XCTAssertTrue(mockMessagingDelegate.shouldShowMessageCalled)
            XCTAssertTrue(mockMessagingDelegate.onShowCalled)
            let webview = fullscreenMessage?.webView as? WKWebView
            XCTAssertEqual(1, webview?.gestureRecognizers?.count)
        }
    
        func testHide() throws {
            _ = messageMonitor.show(message: fullscreenMessage!)
            XCTAssertTrue(messageMonitor.isMessageDisplayed())
            fullscreenMessage?.hide()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 1000)) {
                XCTAssertFalse(self.messageMonitor.isMessageDisplayed())
            }
        }
    
        func testHideNoMessageVisible() throws {
            XCTAssertFalse(messageMonitor.isMessageDisplayed())
            fullscreenMessage?.hide()
            XCTAssertFalse(self.messageMonitor.isMessageDisplayed())
        }
 
        func testOnShowDelegateReturnsFalse() throws {
            expectation = XCTestExpectation(description: "Testing show failed")
            mockFullscreenListener.setExpectation(expectation!)
            mockMessagingDelegate.valueShouldShowMessage = false
            fullscreenMessage?.show()
            wait(for: [expectation!], timeout: 2.0)
            XCTAssertTrue(mockFullscreenListener.onShowFailureCalled)
            XCTAssertTrue(mockMessagingDelegate.shouldShowMessageCalled)
        }
    
        func testShowWhenWebviewAlreadyExists() throws {
            expectation = XCTestExpectation(description: "Testing show when webview already exists")
            mockFullscreenListener.setExpectation(expectation!)
            fullscreenMessage?.webView = WKWebView()
            fullscreenMessage?.show()
            wait(for: [expectation!], timeout: 2.0)
            XCTAssertTrue(mockFullscreenListener.onShowCalled)
            XCTAssertTrue(mockMessagingDelegate.shouldShowMessageCalled)
            XCTAssertTrue(mockMessagingDelegate.onShowCalled)
        }
    
        func testShowWhenWebviewAlreadyExistsDelegateReturnsFalse() throws {
            expectation = XCTestExpectation(description: "Testing show when webview already exists")
            mockFullscreenListener.setExpectation(expectation!)
            fullscreenMessage?.webView = WKWebView()
            mockMessagingDelegate.valueShouldShowMessage = false
            fullscreenMessage?.show()
            wait(for: [expectation!], timeout: 2.0)
            XCTAssertTrue(mockFullscreenListener.onShowFailureCalled)
            XCTAssertTrue(mockMessagingDelegate.shouldShowMessageCalled)
        }
    
        func testHandleJavascriptMessageHappy() throws {
            expectation = XCTestExpectation(description: "Testing handler is properly set")
            fullscreenMessage?.handleJavascriptMessage("testScript", withHandler: handler)
        
            // above code runs on mt, dispatch validation on mt
            DispatchQueue.main.async {
                XCTAssertEqual(1, self.fullscreenMessage?.scriptHandlers.count)
                self.fullscreenMessage?.scriptHandlers["testScript"]!("content")
                self.wait(for: [self.expectation!], timeout: 2.0)
                XCTAssertTrue(self.handlerCalled)
                XCTAssertEqual("content", self.handlerContent as? String)
            }
        }
    
        func testHandleJavascriptMessageWebviewExists() throws {
            expectation = XCTestExpectation(description: "Testing handler is properly set")
            fullscreenMessage?.webView = WKWebView()
            fullscreenMessage?.handleJavascriptMessage("testScript", withHandler: handler)
        
            // above code runs on mt, dispatch validation on mt
            DispatchQueue.main.async {
                XCTAssertEqual(1, self.fullscreenMessage?.scriptHandlers.count)
                self.fullscreenMessage?.scriptHandlers["testScript"]!("content")
                self.wait(for: [self.expectation!], timeout: 2.0)
                XCTAssertTrue(self.handlerCalled)
                XCTAssertEqual("content", self.handlerContent as? String)
            }
        }
    
        func testHandleJavascriptMessageHandlerExistsForName() throws {
            fullscreenMessage?.scriptHandlers["testScript"] = handler
            XCTAssertEqual(1, fullscreenMessage?.scriptHandlers.count)
            fullscreenMessage?.handleJavascriptMessage("testScript", withHandler: handler)
            XCTAssertEqual(1, fullscreenMessage?.scriptHandlers.count)
        }
    
        func testSetAssetMapHappy() throws {
            // setup
            fullscreenMessage?.payload = "message with a token"
            let testAssetMap = ["token":"value replaced"]
        
            // test
            fullscreenMessage?.setAssetMap(testAssetMap)
        
            // verify
            XCTAssertEqual("message with a value replaced", fullscreenMessage?.payloadUsingLocalAssets)
        }
    
        func testSetAssetMapNoMatchingTokens() throws {
            // setup
            fullscreenMessage?.payload = "message with a token"
            let testAssetMap = ["nope":"value replaced"]
        
            // test
            fullscreenMessage?.setAssetMap(testAssetMap)
        
            // verify
            XCTAssertEqual("message with a token", fullscreenMessage?.payloadUsingLocalAssets)
        }

        func testSetAssetMapNilMap() throws {
            // test
            fullscreenMessage?.setAssetMap(nil)
        
            // verify
            XCTAssertNil(fullscreenMessage?.payloadUsingLocalAssets)
        }
    
        func testSetAssetMapEmptyMap() throws {
            // setup
            let testAssetMap: [String: String] = [:]
        
            // test
            fullscreenMessage?.setAssetMap(testAssetMap)
        
            // verify
            XCTAssertNil(fullscreenMessage?.payloadUsingLocalAssets)
        }
    
        func testUserContentControllerWithScriptHandler() throws {
            expectation = XCTestExpectation(description: "JavaScript handler was called")
            let controller = WKUserContentController()
            let message = MockWKScriptMessage(name: "testScript", body: "body")
            fullscreenMessage?.handleJavascriptMessage("testScript", withHandler: handler)
            // above code runs on mt, dispatch validation on mt
            DispatchQueue.main.async {
                self.fullscreenMessage?.userContentController(controller, didReceive: message)
                self.wait(for: [self.expectation!], timeout: 1.0)
                XCTAssertTrue(self.handlerCalled)
                XCTAssertEqual("body", self.handlerContent as? String)
            }
        }
    
        func testUserContentControllerNoMatchingScriptHandler() throws {
            expectation = XCTestExpectation(description: "JavaScript handler was called")
            expectation?.isInverted = true
            let controller = WKUserContentController()
            let message = MockWKScriptMessage(name: "not a matching message", body: "body")
            fullscreenMessage?.handleJavascriptMessage("testScript", withHandler: handler)
            fullscreenMessage?.userContentController(controller, didReceive: message)
            wait(for: [expectation!], timeout: 1.0)
            XCTAssertFalse(handlerCalled)
            XCTAssertNil(handlerContent)
        }
    }
#endif

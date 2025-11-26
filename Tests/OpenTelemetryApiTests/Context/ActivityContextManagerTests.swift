/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

#if canImport(os.activity)
  @testable import OpenTelemetryApi
  import OpenTelemetryTestUtils
  import XCTest

  @MainActor
  class ActivityContextManagerTests: OpenTelemetryContextTestCase {
    override var contextManagers: [any ContextManager] {
      Self.activityContextManagers()
    }

    let defaultTracer = DefaultTracer.instance
    let firstBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, UInt8(ascii: "a")]

    nonisolated(unsafe) var spanContext: SpanContext!

    override func setUp() {
      spanContext = SpanContext.create(traceId: TraceId(fromBytes: firstBytes), spanId: SpanId(fromBytes: firstBytes, withOffset: 8), traceFlags: TraceFlags(), traceState: TraceState())
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    override func tearDown() {
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    func testStartAndEndSpanInAsyncQueue() {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncQueue1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)
      let expec = expectation(description: "testStartAndEndSpanInAsyncQueue")
      let tracer = defaultTracer
      DispatchQueue.global().async { @Sendable in
        let span2 = tracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncQueue2").startSpan()
        ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span2)
        span2.end()
        expec.fulfill()
      }
      waitForExpectations(timeout: 30)
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    func testStartAndEndSpanInAsyncQueueTwice() {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncQueueTwice1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)
      let expec = expectation(description: "testStartAndEndSpanInAsyncQueueTwice1")
      let expec2 = expectation(description: "testStartAndEndSpanInAsyncQueueTwice2")
      let tracer = defaultTracer
      DispatchQueue.global().async { @Sendable in
        let span2 = tracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncQueueTwice2").startSpan()
        ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span2)
        span2.end()
        expec.fulfill()
      }
      DispatchQueue.global().async { @Sendable in
        let span3 = tracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncQueueTwice3").startSpan()
        ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span3)
        span3.end()
        expec2.fulfill()
      }
      waitForExpectations(timeout: 30)
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    func createSpan(parentSpan: Span, name: String) -> Span {
      var activeSpan = ActivityContextManager.instance.getCurrentContextValue(forKey: .span)
      XCTAssert(activeSpan === parentSpan)
      let newSpan = defaultTracer.spanBuilder(spanName: name).startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: newSpan)
      activeSpan = ActivityContextManager.instance.getCurrentContextValue(forKey: .span)
      XCTAssert(activeSpan === newSpan)
      return newSpan
    }

    func endSpanAndValidateContext(span: Span, parentSpan: Span?) {
      var activeSpan = ActivityContextManager.instance.getCurrentContextValue(forKey: .span)
      XCTAssert(activeSpan === span)
      span.end()
      activeSpan = ActivityContextManager.instance.getCurrentContextValue(forKey: .span)
      XCTAssert(activeSpan === parentSpan)
    }

    func testContextPropagationTwoSequentialChildSpans() {
      let parentSpan = defaultTracer.spanBuilder(spanName: "Parent").startSpan()
      OpenTelemetry.instance.contextProvider.setActiveSpan(parentSpan)

      let child1 = defaultTracer.spanBuilder(spanName: "child1").startSpan()
      child1.end()

      let child2 = defaultTracer.spanBuilder(spanName: "child2").startSpan()
      child2.end()

      parentSpan.end()

      XCTAssertEqual(parentSpan.context.traceId, child1.context.traceId)
      XCTAssertEqual(parentSpan.context.traceId, child2.context.traceId)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testStartAndEndSpanInAsyncTask() {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTask").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      let expec = expectation(description: "testStartAndEndSpanInAsyncTask")
      Task {
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)
        await createAsyncSpan(parentSpan: span1, name: "asyncSpan")
        XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)
        expec.fulfill()
      }
      waitForExpectations(timeout: 30)
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testStartAndEndSpanInAsyncTaskAsync() async {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTask").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)

      await createAsyncSpan(parentSpan: span1, name: "asyncSpan")
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testStartAndEndSpanInAsyncTaskTwice() {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTaskTwice1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      let expec = expectation(description: "testStartAndEndSpanInAsyncTaskTwice")
      Task {
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)
        await createAsyncSpan(parentSpan: span1, name: "Child1")
        await createAsyncSpan(parentSpan: span1, name: "Child2")
        XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)

        expec.fulfill()
      }
      waitForExpectations(timeout: 30)
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testStartAndEndSpanInAsyncTaskTwiceAsync() async {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTaskTwice1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)
      await createAsyncSpan(parentSpan: span1, name: "Child1")
      await createAsyncSpan(parentSpan: span1, name: "Child2")
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)

      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func createAsyncSpan(parentSpan: Span?, name: String) async {
      let activeSpan = ActivityContextManager.instance.getCurrentContextValue(forKey: .span)
      XCTAssert(activeSpan === parentSpan)
      let newSpan = defaultTracer.spanBuilder(spanName: name).startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: newSpan)
      endSpanAndValidateContext(span: newSpan, parentSpan: parentSpan)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testStartAndEndSpanInAsyncTaskAnidated() {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTaskAnidated1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      let expec = expectation(description: "testStartAndEndSpanInAsyncTaskAnidated")
      Task {
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)
        await createAsyncSpanOutside(parentSpan: span1)
        XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)
        expec.fulfill()
      }
      waitForExpectations(timeout: 30)
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testStartAndEndSpanInAsyncTaskAnidatedAsync() async {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTaskAnidated1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)
      await createAsyncSpanOutside(parentSpan: span1)
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func createAsyncSpanOutside(parentSpan: Span) async {
      let activeSpan = ActivityContextManager.instance.getCurrentContextValue(forKey: .span)
      XCTAssert(activeSpan === parentSpan)
      let newSpan = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTaskAnidated2").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: newSpan)
      await createAsyncSpanInside(parentSpan: newSpan)
      endSpanAndValidateContext(span: newSpan, parentSpan: parentSpan)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func createAsyncSpanInside(parentSpan: Span) async {
      let activeSpan = ActivityContextManager.instance.getCurrentContextValue(forKey: .span)
      XCTAssert(activeSpan === parentSpan)
      let newSpan = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTaskAnidated3").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: newSpan)
      await createAsyncSpan(parentSpan: newSpan, name: "asyncSpanInside")
      endSpanAndValidateContext(span: newSpan, parentSpan: parentSpan)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    // First created task correctly does not inherit activity when created detached
    func testStartAndEndSpanInAsyncTaskDetachedWithParent() {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTask1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      let expec = expectation(description: "testStartAndEndSpanInAsyncTaskWithParent")
      let tracer = defaultTracer
      Task.detached { @Sendable in
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === nil)
        let newSpan = tracer.spanBuilder(spanName: "detachedspan").startSpan()
        ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: newSpan)
        newSpan.end()
        XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
        expec.fulfill()
      }
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
      waitForExpectations(timeout: 30)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    // First created task correctly does not inherit activity when created detached
    func testStartAndEndSpanInAsyncTaskDetachedWithParentAsync() async {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTask1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      let expec = expectation(description: "testStartAndEndSpanInAsyncTaskWithParent")
      let tracer = defaultTracer
      Task.detached { @Sendable in
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === nil)
        let newSpan = tracer.spanBuilder(spanName: "detachedspan").startSpan()
        ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: newSpan)
        newSpan.end()
        XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
        expec.fulfill()
      }
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
      await fulfillment(of: [expec], timeout: 30)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    // First created task correctly inherits activity when created, so assigns the proper parent
    func testStartAndEndSpanInAsyncTaskWithParent() {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTask1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      let expec = expectation(description: "testStartAndEndSpanInAsyncTaskWithParent")
      Task {
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)
        await self.createAsyncSpan(parentSpan: span1, name: "AsyncSpan")
        XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)
        expec.fulfill()
      }
      waitForExpectations(timeout: 30)
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    // First created task correctly inherits activity when created, so assigns the proper parent
    func testStartAndEndSpanInAsyncTaskWithParentAsync() async {
      let span1 = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTask1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      let expec = expectation(description: "testStartAndEndSpanInAsyncTaskWithParent")
      Task {
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)
        await self.createAsyncSpan(parentSpan: span1, name: "AsyncSpan")
        XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === span1)
        expec.fulfill()
      }
      await fulfillment(of: [expec], timeout: 30)
      span1.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testActiveSpanIsKeptPerTask() {
      let expectation1 = expectation(description: "firstSpan created")
      let expectation2 = expectation(description: "secondSpan created")

      let parent = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTaskTwice").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: parent)
      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)

      Task {
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
        await createAsyncSpan(parentSpan: parent, name: "AsyncSpan1")
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
        expectation1.fulfill()
      }

      Task {
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
        await createAsyncSpan(parentSpan: parent, name: "AsyncSpan2")
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
        expectation2.fulfill()
      }

      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
      waitForExpectations(timeout: 5, handler: nil)
      parent.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testRemoveContextValuesFromSpan() {
      // Create a span
      let span1 = defaultTracer.spanBuilder(spanName: "span1").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: span1)
      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === span1)

      // Add it to one parent in one thread
      let tracer = defaultTracer
      DispatchQueue.global().async { @Sendable in
        let parent1 = tracer.spanBuilder(spanName: "parent1").startSpan()
        ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: parent1)
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent1)

        let activeSpan = ActivityContextManager.instance.getCurrentContextValue(forKey: .span)
        XCTAssert(activeSpan === parent1)
        parent1.end()
      }

      // Add it to another parent in another thread
      DispatchQueue.global().async { @Sendable in
        let parent2 = tracer.spanBuilder(spanName: "parent2").startSpan()
        ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: parent2)
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent2)

        let activeSpan = ActivityContextManager.instance.getCurrentContextValue(forKey: .span)
        XCTAssert(activeSpan === parent2)
        parent2.end()
      }

      sleep(1)
      // Remove all the contexts from the span and check if the Context is nil
      // Ending the span will remove all the context associated with it, dont need to call removeContextValue explicitly
      // ActivityContextManager.instance.removeContextValue(forKey: .span, value: span1)
      span1.end()
      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testActiveSpanIsKeptPerTaskAsync() async {
      let expectation1 = expectation(description: "firstSpan created")
      let expectation2 = expectation(description: "secondSpan created")

      let parent = defaultTracer.spanBuilder(spanName: "testStartAndEndSpanInAsyncTaskTwice").startSpan()
      ActivityContextManager.instance.setCurrentContextValue(forKey: .span, value: parent)
      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)

      Task {
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
        await createAsyncSpan(parentSpan: parent, name: "AsyncSpan1")
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
        expectation1.fulfill()
      }

      Task {
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
        await createAsyncSpan(parentSpan: parent, name: "AsyncSpan2")
        XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
        expectation2.fulfill()
      }

      XCTAssert(ActivityContextManager.instance.getCurrentContextValue(forKey: .span) === parent)
      await fulfillment(of: [expectation1, expectation2], timeout: 5)
      parent.end()
      XCTAssert(OpenTelemetry.instance.contextProvider.activeSpan === nil)
    }
  }
#endif

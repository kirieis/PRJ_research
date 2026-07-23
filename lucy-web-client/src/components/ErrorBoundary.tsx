"use client";

import React, { Component, ErrorInfo, ReactNode } from "react";

interface Props {
  children?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

export default class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null,
    errorInfo: null,
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error, errorInfo: null };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("Uncaught error:", error, errorInfo);
    this.setState({ errorInfo });
  }

  public render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: "40px", backgroundColor: "#ffdddd", color: "#990000", height: "100vh", fontFamily: "monospace", overflow: "auto" }}>
          <h1>âš ï¸ FATAL CLIENT CRASH</h1>
          <p>Please take a screenshot of this error and send it to the AI.</p>
          <hr />
          <h3>Error:</h3>
          <pre style={{ whiteSpace: "pre-wrap" }}>{this.state.error && this.state.error.toString()}</pre>
          <h3>Stack Trace:</h3>
          <pre style={{ whiteSpace: "pre-wrap" }}>{this.state.errorInfo && this.state.errorInfo.componentStack}</pre>
        </div>
      );
    }

    return this.props.children;
  }
}

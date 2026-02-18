# ansuz-layout

Clay-style layout engine for terminal applications.

## Overview

ansuz-layout provides a 3-pass layout engine for building UIs:
- **Pass 1 (Measure)**: Bottom-up calculation of content sizes
- **Pass 2 (Resolve)**: Top-down resolution of Grow/Percent
- **Pass 3 (Position)**: Top-down positioning with alignment

## Key Features

### Sizing
- fixed(value) - Fixed size in cells
- percent(value) - Percentage of parent (0.0 to 1.0)
- fit() - Fit to content
- grow(weight) - Fill remaining space

### Layout Directions
- .LeftToRight - Horizontal row
- .TopToBottom - Vertical column
- .ZStack - Stacked overlay

### Alignment
- Horizontal: Left, Center, Right
- Vertical: Top, Center, Bottom

### Containers
- Padding
- Gap between children
- Overflow handling (Hidden, Visible, Scroll)
- Text wrapping support

### Render Commands
The finish_layout() function returns an array of RenderCommand structs:
- .Text - Render text at rect
- .Box - Draw border box
- .Rect - Fill rectangle

## Dependencies

- ansuz-color - For Style types
- ansuz-buffer - For text measurement

## Independence

This package computes layout positions but does NOT render directly.
The caller is responsible for executing render commands to the buffer.
This makes a layout engine reusable for other targets (GUI, web, etc.).

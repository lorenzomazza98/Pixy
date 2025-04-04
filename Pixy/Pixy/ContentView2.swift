//
//  ContentView2.swift
//  Pixy
//
//  Created by Lorenzo Mazza on 19/03/25.
//


/*
import SwiftUI

enum DrawingTool {
    case pen, verticalMirrorPen, paintBucket, paintAllSameColor, eraser, stroke,
         rectangle, circle, move, shapeSelection, rectangleSelection, lassoSelection,
         lighten, dithering, colorPicker
}

enum ImageFormat {
    case jpeg, png
}

struct PixelArtGridView: View {
    // Grid State
    @State private var rows = 16
    @State private var columns = 16
    @State private var cellColors: [[Color]]
    @State private var currentColor: Color = .black
    @State private var backgroundColor: Color = .gray
    @State private var separatorWidth: CGFloat = 1.0
    @State private var isGridEnabled = true
    @State private var gridSpacing: Int = 1
    @State private var separatorColor: Color = .black
    @State private var maintainAspectRatio = true
    
    // UI State
    @State private var gridName = "My Pixel Art"
    @State private var isEditingName = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingGridSettings = false
    @State private var showingSaveOptions = false
    @State private var showRowCoordinates = false
    @State private var showColumnCoordinates = false
    @State private var currentPixelCoordinates: (row: Int, column: Int)?
    
    // History Management
    @State private var history: [[[Color]]] = []
    @State private var historyIndex = -1
    @State private var canUndo = false
    @State private var canRedo = false
    
    

    init() {
        _cellColors = State(initialValue: Array(repeating: Array(repeating: .gray, count: 16), count: 16))
    }

    var body: some View {
        VStack {
            // Grid Name Editor
            HStack {
                if isEditingName {
                    TextField("Grid Name", text: $gridName, onCommit: { isEditingName = false })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                } else {
                    Text(gridName)
                        .font(.title)
                        .onTapGesture { isEditingName = true }
                }
            }
            .padding()
            
            // Main Content
            HStack(alignment: .top, spacing: 20) {
                // Tools Panel
                VStack(spacing: 10) {
                    toolPair(.pen, .verticalMirrorPen)
                    toolPair(.paintBucket, .paintAllSameColor)
                    toolPair(.eraser, .stroke)
                    toolPair(.rectangle, .circle)
                    toolPair(.move, .shapeSelection)
                    toolPair(.rectangleSelection, .lassoSelection)
                    toolPair(.lighten, .dithering)
                    toolButton(.colorPicker)
                }
                .padding(10)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                
                // Grid View
                gridView()
            }
            
            // Bottom Control Panel
            controlPanel()
        }
        .padding()
        .alert("Warning", isPresented: $showingAlert) {
            Button("Clear", role: .destructive) { clearBoard() }
            Button("Cancel", role: .cancel) { }
        } message: { Text(alertMessage) }
        .sheet(isPresented: $showingGridSettings) { gridSettingsView() }
        .actionSheet(isPresented: $showingSaveOptions) {
            ActionSheet(title: Text("Export Format"), buttons: [
                .default(Text("JPEG")) { saveCreation(as: .jpeg) },
                .default(Text("PNG")) { saveCreation(as: .png) },
                .cancel()
            ])
        }
    }
    
    // MARK: - Grid View
    private func gridView() -> some View {
        GeometryReader { geometry in
            let cellSize = calculateCellSize(geometry: geometry)
            VStack(spacing: isGridEnabled ? separatorWidth : 0) {
                ForEach(0..<rows/gridSpacing, id: \.self) { row in
                    HStack(spacing: isGridEnabled ? separatorWidth : 0) {
                        ForEach(0..<columns/gridSpacing, id: \.self) { col in
                            let actualRow = row * gridSpacing
                            let actualCol = col * gridSpacing
                            
                            Rectangle()
                                .fill(cellColors[actualRow][actualCol])
                                .frame(width: cellSize, height: cellSize)
                                .border(isGridEnabled ? separatorColor : .clear, width: separatorWidth)
                                .onTapGesture { handleCellTap(row: actualRow, column: actualCol) }
                        }
                    }
                }
            }
            .aspectRatio(CGFloat(columns)/CGFloat(rows), contentMode: .fit)
        }
    }
    
    // MARK: - Toolbox Components
    private func toolPair(_ tool1: DrawingTool, _ tool2: DrawingTool) -> some View {
        HStack {
            toolButton(tool1)
            toolButton(tool2)
        }
    }
    
    private func toolButton(_ tool: DrawingTool) -> some View {
        Button {
            currentTool = tool
        } label: {
            Image(systemName: toolIcon(tool))
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .foregroundColor(currentTool == tool ? .white : .primary)
                .background(currentTool == tool ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private func toolIcon(_ tool: DrawingTool) -> String {
        switch tool {
        case .pen: return "pencil"
        case .verticalMirrorPen: return "arrow.left.and.right.righttriangle.right.righttriangle"
        case .paintBucket: return "paintbrush.fill"
        case .paintAllSameColor: return "paintpalette.fill"
        case .eraser: return "eraser.fill"
        case .stroke: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .move: return "hand.draw"
        case .shapeSelection: return "lasso"
        case .rectangleSelection: return "rectangle.dashed"
        case .lassoSelection: return "lasso.and.sparkles"
        case .lighten: return "sun.max"
        case .dithering: return "square.grid.3x3.square"
        case .colorPicker: return "eyedropper"
        }
    }
    
    // MARK: - Control Panel
    private func controlPanel() -> some View {
        HStack(spacing: 20) {
            Button(action: { showingGridSettings.toggle() }) {
                Image(systemName: "gear").font(.title2)
            }
            
            Button("Export") { showingSaveOptions.toggle() }
            
            Button("Clear") {
                alertMessage = "Clear entire artwork? This cannot be undone."
                showingAlert.toggle()
            }
            
            HStack {
                Button("Undo") { undo() }.disabled(!canUndo)
                Button("Redo") { redo() }.disabled(!canRedo)
            }
            
            if let (row, col) = currentPixelCoordinates {
                Text("(\(row), \(col))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.1)))
    }
    
    // MARK: - Grid Settings View
    private func gridSettingsView() -> some View {
        NavigationStack {
            Form {
                Section("Dimensions") {
                    dimensionControl("Rows", $rows)
                    dimensionControl("Columns", $columns)
                    Toggle("Maintain Aspect Ratio", isOn: $maintainAspectRatio)
                }
                
                Section("Appearance") {
                    Toggle("Show Grid", isOn: $isGridEnabled)
                    Slider(value: $separatorWidth, in: 0...5, step: 0.5) {
                        Text("Grid Line Width: \(separatorWidth, specifier: "%.1f")")
                    }
                    Picker("Grid Spacing", selection: $gridSpacing) {
                        ForEach(gridSpacingOptions, id: \.self) { Text("\($0)x\($0)") }
                    }
                }
                
                Section("Colors") {
                    ColorPicker("Drawing Color", selection: $currentColor)
                    ColorPicker("Background Color", selection: $backgroundColor)
                    ColorPicker("Grid Color", selection: $separatorColor)
                }
                
                Section("Coordinates") {
                    Toggle("Show Row Numbers", isOn: $showRowCoordinates)
                    Toggle("Show Column Numbers", isOn: $showColumnCoordinates)
                }
            }
            .navigationTitle("Grid Settings")
            .toolbar {
                Button("Done") { showingGridSettings = false }
            }
        }
        .frame(width: 400, height: 500)
    }
    
    // MARK: - Core Functionality
    private func handleCellTap(row: Int, column: Int) {
        currentPixelCoordinates = (row, column)
        
        switch currentTool {
        case .pen:
            paintCell(row, column, color: currentColor)
        case .verticalMirrorPen:
            paintCell(row, column, color: currentColor)
            paintCell(rows - 1 - row, column, color: currentColor)
        case .eraser:
            paintCell(row, column, color: backgroundColor)
        case .paintBucket:
            floodFill(startRow: row, startCol: column)
        case .paintAllSameColor:
            let targetColor = cellColors[row][column]
            paintAllMatching(color: targetColor)
        case .lighten:
            lightenCell(row, column)
        case .dithering:
            ditherCell(row, column)
        case .colorPicker:
            currentColor = cellColors[row][column]
        default:
            break // Implement other tools as needed
        }
    }
    
    private func paintCell(_ row: Int, _ column: Int, color: Color) {
        guard row < rows && column < columns else { return }
        cellColors[row][column] = color
        saveToHistory()
    }
    
    private func floodFill(startRow: Int, startCol: Int) {
        let targetColor = cellColors[startRow][startCol]
        var stack = [(startRow, startCol)]
        
        while !stack.isEmpty {
            let (row, col) = stack.removeLast()
            guard row >= 0 && row < rows && col >= 0 && col < columns else { continue }
            guard cellColors[row][col] == targetColor else { continue }
            
            cellColors[row][col] = currentColor
            stack.append((row+1, col))
            stack.append((row-1, col))
            stack.append((row, col+1))
            stack.append((row, col-1))
        }
        saveToHistory()
    }
    
    private func paintAllMatching(color: Color) {
        for row in 0..<rows {
            for col in 0..<columns {
                if cellColors[row][col] == color {
                    cellColors[row][col] = currentColor
                }
            }
        }
        saveToHistory()
    }
    
    private func lightenCell(_ row: Int, _ column: Int) {
        let colorFunction: (Double) -> Color = { value in Color(red: value, green: 0.5, blue: 0.5) }
        let someValue: Double = 0.5
        let result = colorFunction(someValue) // Correct usage
        saveToHistory()
    }
    
    private func ditherCell(_ row: Int, _ column: Int) {
        cellColors[row][column] = (row + column) % 2 == 0 ? currentColor : backgroundColor
        saveToHistory()
    }
    
    // MARK: - History Management
    private func saveToHistory() {
        if historyIndex < history.count - 1 {
            history.removeLast(history.count - historyIndex - 1)
        }
        history.append(cellColors)
        historyIndex = history.count - 1
        updateUndoRedoState()
    }
    
    private func undo() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        cellColors = history[historyIndex]
        updateUndoRedoState()
    }
    
    private func redo() {
        guard historyIndex < history.count - 1 else { return }
        historyIndex += 1
        cellColors = history[historyIndex]
        updateUndoRedoState()
    }
    
    private func updateUndoRedoState() {
        canUndo = historyIndex > 0
        canRedo = historyIndex < history.count - 1
    }
    
    // MARK: - Utility Functions
    private func calculateCellSize(geometry: GeometryProxy) -> CGFloat {
        let totalSize = min(geometry.size.width, geometry.size.height)
        return totalSize / CGFloat(max(rows, columns))
    }
    
    private func dimensionControl(_ label: String, _ value: Binding<Int>) -> some View {
        HStack {
            Text(label)
            Stepper(value: value, in: 1...32) {
                Text("\(value.wrappedValue)")
                    .frame(width: 40)
            }
        }
    }
    
    private func clearBoard() {
        cellColors = Array(repeating: Array(repeating: backgroundColor, count: columns), count: rows)
        history.removeAll()
        historyIndex = -1
        updateUndoRedoState()
    }
    
    // MARK: - Export Functionality
    private func saveCreation(as format: ImageFormat) {
        let renderer = ImageRenderer(content: ExportView(grid: self))
        renderer.scale = 3.0
        
        guard let uiImage = renderer.uiImage else { return }
        
        let saver = ImageSaver()
        switch format {
        case .jpeg:
            if let data = uiImage.jpegData(compressionQuality: 0.9) {
                saver.saveImage(data: data)
            }
        case .png:
            if let data = uiImage.pngData() {
                saver.saveImage(data: data)
            }
        }
    }
    
    private struct ExportView: View {
        let grid: PixelArtGridView
        
        var body: some View {
            grid.gridView()
                .frame(width: 500, height: 500)
        }
    }
}

class ImageSaver: NSObject {
    func saveImage(data: Data) {
        guard let image = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveComplete), nil)
    }
    
    @objc func saveComplete(_ image: UIImage, error: Error?, context: UnsafeRawPointer) {
        if let error = error {
            print("Save error: \(error.localizedDescription)")
        } else {
            print("Save successful")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PixelArtGridView()
    }
}

*/

import SwiftUI

struct PixelArtGridView: View {
    @State private var rows = 16
    @State private var columns = 16
    @State private var cellColors: [[Color]] = []
    @State private var currentColor: Color = .black
    @State private var backgroundColor: Color = .gray
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingGridSettings = false
    @State private var separatorWidth: CGFloat = 1.0
    @State private var isGridEnabled = true
    @State private var gridSpacing: Int = 1
    @State private var separatorColor: Color = .black
    @State private var maintainAspectRatio = true
    @State private var gridName = "My Pixel Art"
    @State private var isEditingName = false
    @State private var showingSaveOptions = false
    @State private var showRowCoordinates = false
    @State private var showColumnCoordinates = false
    @State private var history: [[[Color]]] = []
    @State private var historyIndex = -1
    @State private var canUndo = false
    @State private var canRedo = false
    @State private var currentPixelCoordinates: (row: Int, column: Int)?
    @State private var isHovering = false



    let gridSpacingOptions = [1, 2, 4, 8, 16, 32, 64]

    init() {
        _cellColors = State(initialValue: Array(repeating: Array(repeating: Color.gray, count: 16), count: 16))
    }
    
    var body: some View {
        VStack {
            HStack {
                if isEditingName {
                    TextField("Enter grid name", text: $gridName, onCommit: {
                        isEditingName = false
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(gridName)
                        .font(.title)
                        .onTapGesture {
                            isEditingName = true
                        }
                }
            }
            .padding()
            
            gridView() // Add this line to bring back the grid
            
            HStack(spacing: 15) {
                Button {
                    showingGridSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                }

                Button("Export Creation") {
                    showingSaveOptions = true
                }

                if (showRowCoordinates || showColumnCoordinates), let coords = currentPixelCoordinates {
                    Text("(\(coords.row), \(coords.column))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.0)))
        }
        .padding()
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Invalid Input"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showingGridSettings) {
            gridSettingsView()
        }
        .actionSheet(isPresented: $showingSaveOptions) {
            ActionSheet(title: Text("Export Creation"), message: Text("Choose a format"), buttons: [
                .default(Text("Export as JPEG")) { saveCreation(as: .jpeg) },
                .default(Text("Export as PNG")) { saveCreation(as: .png) },
                .cancel()
            ])
        }
    }

    
    private func flipVertically() {
        saveToHistory()
        cellColors = cellColors.reversed()
    }

    private func flipHorizontally() {
        saveToHistory()
        cellColors = cellColors.map { $0.reversed() }
    }

    private func rotate90Degrees() {
        saveToHistory()
        var newColors = Array(repeating: Array(repeating: backgroundColor, count: rows), count: columns)
        for i in 0..<rows {
            for j in 0..<columns {
                newColors[j][rows - 1 - i] = cellColors[i][j]
            }
        }
        cellColors = newColors
        swap(&rows, &columns)
    }

    private func centerColoredPixels() {
        saveToHistory()
        var minRow = rows, maxRow = 0, minCol = columns, maxCol = 0
        for i in 0..<rows {
            for j in 0..<columns {
                if cellColors[i][j] != backgroundColor {
                    minRow = min(minRow, i)
                    maxRow = max(maxRow, i)
                    minCol = min(minCol, j)
                    maxCol = max(maxCol, j)
                }
            }
        }
        let rowShift = (rows - (maxRow - minRow + 1)) / 2 - minRow
        let colShift = (columns - (maxCol - minCol + 1)) / 2 - minCol
        var newColors = Array(repeating: Array(repeating: backgroundColor, count: columns), count: rows)
        for i in minRow...maxRow {
            for j in minCol...maxCol {
                newColors[i + rowShift][j + colShift] = cellColors[i][j]
            }
        }
        cellColors = newColors
    }

    private func saveToHistory() {
        if historyIndex >= 0 {
            history = Array(history[0...historyIndex])
        } else {
            history = []
        }
        history.append(cellColors)
        historyIndex = history.count - 1
        canUndo = true
        canRedo = false
    }


    private func undo() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        cellColors = history[historyIndex]
        canRedo = true
        canUndo = historyIndex > 0
    }

    private func redo() {
        guard historyIndex < history.count - 1 else { return }
        historyIndex += 1
        cellColors = history[historyIndex]
        canUndo = true
        canRedo = historyIndex < history.count - 1
    }

    private func applyChanges() {
        // Apply any pending changes here
        saveToHistory()
    }
    
    // Update gridView to show coordinates
    private func gridView() -> some View {
        GeometryReader { geometry in
            let totalSize = min(geometry.size.width, geometry.size.height)
            let effectiveRows = rows / gridSpacing
            let effectiveColumns = columns / gridSpacing
            let cellSize = totalSize / CGFloat(max(effectiveRows, effectiveColumns))
            
            VStack(spacing: isGridEnabled ? separatorWidth : 0) {
                ForEach(0..<effectiveRows, id: \.self) { row in
                    HStack(spacing: isGridEnabled ? separatorWidth : 0) {
                        ForEach(0..<effectiveColumns, id: \.self) { column in
                            Rectangle()
                                .fill(getCellColor(row: row * gridSpacing, column: column * gridSpacing))
                                .frame(width: cellSize, height: cellSize)
                                .border(isGridEnabled ? separatorColor : .clear, width: separatorWidth)
                                .onTapGesture {
                                    toggleCellColor(row: row * gridSpacing, column: column * gridSpacing)
                                    currentPixelCoordinates = (row: row * gridSpacing, column: column * gridSpacing)
                                }
                        }
                    }
                }
            }
        }
        .aspectRatio(contentMode: .fit)
    }

    private func getCellColor(row: Int, column: Int) -> Color {
        cellColors[row][column]
    }
    
    private func gridSettingsView() -> some View {
        VStack(spacing: 20) {
            headerView()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    gridDimensionsSection()
                    gridAppearanceSection()
                    colorSection()
                    coordinatesSection()
                    transformationsSection()
                    historySection()
                }
                .padding()
            }
        }
        .frame(width: 600, height: 600)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(20)
        .ornament(attachmentAnchor: .scene(.bottom)) {
            Button("Apply Changes") {
                applyChanges()
                showingGridSettings = false
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
    private func coordinatesSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Toggle("Show Row Coordinates", isOn: $showRowCoordinates)
            Toggle("Show Column Coordinates", isOn: $showColumnCoordinates)
        }
    }

    private func transformationsSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Button("Flip Vertically") { flipVertically() }
            Button("Flip Horizontally") { flipHorizontally() }
            Button("Rotate 90 Degrees") { rotate90Degrees() }
            Button("Center Colored Pixels") { centerColoredPixels() }
        }
    }

    private func historySection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Button("Undo") { undo() }
                    .disabled(!canUndo)
                Button("Redo") { redo() }
                    .disabled(!canRedo)
            }
        }
    }

    private func headerView() -> some View {
        HStack {
            Button(action: { showingGridSettings = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
            }
            Spacer()
            Text("Grid Settings")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
        }
        .padding()
    }

    private func gridDimensionsSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            dimensionControl(label: "Rows", value: $rows)
            dimensionControl(label: "Columns", value: $columns)
            Toggle("Maintain Aspect Ratio", isOn: $maintainAspectRatio)
        }
    }

    private func gridAppearanceSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Toggle("Enable Grid", isOn: $isGridEnabled)
            
            VStack(alignment: .leading) {
                Text("Separator Width: \(separatorWidth, specifier: "%.1f") px")
                Slider(value: $separatorWidth, in: 0...5, step: 0.5)
            }
            
            VStack(alignment: .leading) {
                Text("Grid Spacing")
                Picker("", selection: $gridSpacing) {
                    ForEach(gridSpacingOptions, id: \.self) { option in
                        Text("\(option)x\(option)")
                            .tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }

    private func colorSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            ColorPicker("Separators Color", selection: $separatorColor)
            ColorPicker("Draw Color", selection: $currentColor)
            ColorPicker("Background Color", selection: $backgroundColor)
                .onChange(of: backgroundColor) { _ in
                    updateBackgroundColor()
                }
        }
    }
    
    private func gridSpacingControl() -> some View {
        HStack {
            Text("Grid Spacing:")
            Picker("", selection: $gridSpacing) {
                ForEach(gridSpacingOptions, id: \.self) { option in
                    Text("\(option)x\(option)").tag(option)
                        .onChange(of: gridSpacing) { _ in
                            updateGridSizeAfterSpacingChange()
                        }
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private func updateGridSizeAfterSpacingChange() {
        // Calculate effective rows and columns based on current spacing
        let newRows = (rows / gridSpacingOptions.last!) * gridSpacing // Adjust rows based on max spacing
        let newColumns = (columns / gridSpacingOptions.last!) * gridSpacing // Adjust columns based on max spacing
        
        // Ensure rows and columns do not exceed 32x32
        rows = min(newRows, 32)
        columns = min(newColumns, 32)

        // Update cellColors array
        cellColors = Array(repeating: Array(repeating: backgroundColor, count: columns), count: rows)
    }

    private func dimensionControl(label: String, value: Binding<Int>) -> some View {
        HStack {
            Text("\(label): \(value.wrappedValue)")
            Spacer()
            Button(action: {
                if value.wrappedValue > 1 {
                    value.wrappedValue -= 1
                    updateGridSize(changedDimension: label == "Rows" ? .rows : .columns)
                }
            }) {
                Image(systemName: "minus.circle.fill")
            }
            .buttonStyle(.borderless)
            Text("\(value.wrappedValue)")
                .frame(width: 40)
            Button(action: {
                if value.wrappedValue < 32 {
                    value.wrappedValue += 1
                    updateGridSize(changedDimension: label == "Rows" ? .rows : .columns)
                }
            }) {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.borderless)
        }
    }

    
    private enum ChangedDimension {
        case rows, columns
    }
    
    private func updateGridSize(changedDimension: ChangedDimension) {
        if maintainAspectRatio {
            switch changedDimension {
            case .rows:
                columns = rows
            case .columns:
                rows = columns
            }
        }
        rows = min(rows, 32)
        columns = min(columns, 32)
        cellColors = Array(repeating: Array(repeating: backgroundColor, count: columns), count: rows)
    }

    private func toggleCellColor(row: Int, column: Int) {
        let newColor = (cellColors[row][column] == currentColor) ? backgroundColor : currentColor
        for i in 0..<gridSpacing {
            for j in 0..<gridSpacing {
                let actualRow = row + i
                let actualColumn = column + j
                if actualRow < rows && actualColumn < columns {
                    cellColors[actualRow][actualColumn] = newColor
                }
            }
        }
    }
    
    
    private func updateBackgroundColor() {
        let oldBackgroundColor = cellColors[0][0] // Assuming the first cell represents the old background color
        for row in 0..<rows {
            for column in 0..<columns {
                if cellColors[row][column] == oldBackgroundColor {
                    cellColors[row][column] = backgroundColor
                }
            }
        }
    }
    
    func saveCreation(as format: ImageFormat) {
        let renderer = ImageRenderer(content: exportGridView(format: format))
        renderer.scale = 3.0 // Increase resolution
        
        guard let uiImage = renderer.uiImage else {
            print("Failed to render image")
            return
        }
        
        let imageSaver = ImageSaver()
        
        switch format {
        case .jpeg:
            if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                imageSaver.writeToPhotoAlbum(image: UIImage(data: jpegData)!)
            }
        case .png:
            if let pngData = uiImage.pngData() {
                imageSaver.writeToPhotoAlbum(image: UIImage(data: pngData)!)
            }
        }
    }
    
    private func exportGridView(format: ImageFormat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { column in
                        if format == .png {
                            if cellColors[row][column] != backgroundColor {
                                Rectangle()
                                    .fill(cellColors[row][column])
                            } else {
                                Color.clear
                            }
                        } else {
                            Rectangle()
                                .fill(cellColors[row][column])
                        }
                    }
                }
            }
        }
        .aspectRatio(CGFloat(columns) / CGFloat(rows), contentMode: .fit)
        .frame(width: 300, height: 300 * CGFloat(rows) / CGFloat(columns))
    }}

enum ImageFormat {
    case jpeg, png
}

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Image saved successfully")
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    PixelArtGridView()
    
}

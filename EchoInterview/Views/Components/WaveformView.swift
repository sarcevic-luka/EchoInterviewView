import SwiftUI

enum SpeechSentiment {
    case confident
    case neutral
    case hesitant
    
    var color: Color {
        switch self {
        case .confident: return .green
        case .neutral: return .blue
        case .hesitant: return .orange
        }
    }
}

struct WaveformView: View {
    let amplitude: Double
    let sentiment: SpeechSentiment
    let isAnimating: Bool
    
    @State private var phase: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Outer pulsing circle
            Circle()
                .stroke(sentiment.color.opacity(0.2), lineWidth: 2)
                .scaleEffect(scale * 1.3)
            
            // Middle circle
            Circle()
                .stroke(sentiment.color.opacity(0.4), lineWidth: 3)
                .scaleEffect(scale * 1.1)
            
            // Inner filled circle
            Circle()
                .fill(sentiment.color.opacity(0.15))
            
            Circle()
                .stroke(sentiment.color, lineWidth: 4)
            
            // Center icon
            Image(systemName: isAnimating ? "waveform" : "mic.fill")
                .font(.system(size: 30))
                .foregroundStyle(sentiment.color)
        }
        .frame(width: 100, height: 100)
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.1
                }
            }
        }
        .onChange(of: isAnimating) { _, animating in
            if animating {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.1
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 1.0
                }
            }
        }
    }
}

// MARK: - Pulsing Dot Indicator

struct PulsingDotView: View {
    let color: Color
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    scale = 1.4
                    opacity = 0.5
                }
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        WaveformView(amplitude: 0.5, sentiment: .confident, isAnimating: true)
        WaveformView(amplitude: 0.3, sentiment: .neutral, isAnimating: true)
        WaveformView(amplitude: 0.8, sentiment: .hesitant, isAnimating: false)
    }
}

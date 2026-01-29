import SwiftUI

struct InterviewView: View {
    @Bindable var viewModel: InterviewViewModel
    
    var body: some View {
        Text("Interview")
    }
}

#Preview {
    InterviewView(viewModel: InterviewViewModel(
        router: Router(),
        speechService: SpeechService(),
        analysisService: AnalysisService()
    ))
}


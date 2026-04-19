//
//  QuizParticipantReviewLogic.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import Foundation

actor QuizParticipantReviewLogic: QuizParticipantReviewInteractor {
    // MARK: - Properties
    private let presenter: QuizParticipantReviewPresenter
    private let quizService: QuizService
    private let initialData: QuizParticipantReviewModels.InitialData

    private var details: QuizParticipantAnswersDetails?
    private var answersByQuestionId: [String: QuizParticipantAnswer] = [:]
    private var selectedQuestionIndex = 0
    private var scoreDraftByQuestionId: [String: Int] = [:]

    // MARK: - Lifecycle
    init(
        presenter: QuizParticipantReviewPresenter,
        quizService: QuizService,
        initialData: QuizParticipantReviewModels.InitialData
    ) {
        self.presenter = presenter
        self.quizService = quizService
        self.initialData = initialData
    }

    // MARK: - Methods
    func handleViewDidLoad() async {
        do {
            let details = try await quizService.getParticipantAnswers(
                instanceId: initialData.instanceId,
                participantId: initialData.participantId
            )
            self.details = details
            rebuildAnswersIndex(details.answers)
            selectedQuestionIndex = 0
            await presentCurrentState()
        } catch {
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func handleQuestionTap(_ index: Int) async {
        guard let questions = details?.questions, questions.indices.contains(index) else {
            return
        }

        selectedQuestionIndex = index
        await presentCurrentState()
    }

    func handlePreviousQuestionTap() async {
        guard selectedQuestionIndex > 0 else {
            return
        }

        selectedQuestionIndex -= 1
        await presentCurrentState()
    }

    func handleNextQuestionTap() async {
        guard let questions = details?.questions else {
            return
        }
        guard selectedQuestionIndex < questions.count - 1 else {
            return
        }

        selectedQuestionIndex += 1
        await presentCurrentState()
    }

    func handleScoreInputCommit(_ text: String?) async {
        guard let context = selectedOpenQuestionContext() else {
            return
        }

        let normalizedText = normalizedString(text)
        guard normalizedText.isEmpty == false else {
            scoreDraftByQuestionId[context.questionId] = currentScore(
                for: context.question,
                answer: context.answer
            )
            await presentCurrentState()
            return
        }

        guard let parsedValue = Int(normalizedText) else {
            scoreDraftByQuestionId[context.questionId] = currentScore(
                for: context.question,
                answer: context.answer
            )
            await presentCurrentState()
            return
        }

        let maxScore = max(0, context.question.maxScore ?? 0)
        let clampedScore = min(max(parsedValue, 0), maxScore)
        scoreDraftByQuestionId[context.questionId] = clampedScore
        await presentCurrentState()
    }

    func handleDecreaseScoreTap() async {
        guard let context = selectedOpenQuestionContext() else {
            return
        }

        let currentScore = currentScore(for: context.question, answer: context.answer)
        guard currentScore > 0 else {
            return
        }

        scoreDraftByQuestionId[context.questionId] = currentScore - 1
        await presentCurrentState()
    }

    func handleIncreaseScoreTap() async {
        guard let context = selectedOpenQuestionContext() else {
            return
        }

        let maxScore = max(0, context.question.maxScore ?? 0)
        let currentScore = currentScore(for: context.question, answer: context.answer)
        guard currentScore < maxScore else {
            return
        }

        scoreDraftByQuestionId[context.questionId] = currentScore + 1
        await presentCurrentState()
    }

    func handleGradeTap() async {
        guard let context = selectedOpenQuestionContext() else {
            return
        }

        let participantId = normalizedString(initialData.participantId)
        guard participantId.isEmpty == false else {
            return
        }

        let score = currentScore(for: context.question, answer: context.answer)

        do {
            try await quizService.gradeParticipantAnswer(
                instanceId: initialData.instanceId,
                request: GradeAnswerRequest(
                    participantId: participantId,
                    questionId: context.questionId,
                    score: score
                )
            )
            updateAnswerScore(
                questionId: context.questionId,
                existingAnswer: context.answer,
                score: score
            )
            scoreDraftByQuestionId[context.questionId] = score
            await presentCurrentState()
        } catch {
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func handleCompletionTap() async {
        await presenter.presentCompletionInfo(pendingOpenQuestionsCount: pendingOpenQuestionsCount())
    }

    // MARK: - Private Methods
    private func presentCurrentState() async {
        await presenter.presentViewData(makeViewData())
    }

    private func makeViewData() -> QuizParticipantReviewModels.ViewData {
        guard let details else {
            return QuizParticipantReviewModels.ViewData(
                rows: [
                    .header(title: normalizedQuizTitle(from: nil)),
                    .empty(text: "Нет данных по ответам")
                ],
                selectedQuestionIndex: 0,
                checkmarkState: .complete,
                scoreControl: .init(
                    score: 0,
                    maxScore: 0,
                    isMinusEnabled: false,
                    isPlusEnabled: false,
                    isVisible: false
                ),
                bottomControls: .init(
                    isVisible: false,
                    showsGradeButton: false,
                    canGoPrevious: false,
                    canGoNext: false
                )
            )
        }

        guard details.questions.isEmpty == false else {
            return QuizParticipantReviewModels.ViewData(
                rows: [
                    .header(title: normalizedQuizTitle(from: details.instance?.title)),
                    .empty(text: "Нет вопросов")
                ],
                selectedQuestionIndex: 0,
                checkmarkState: .complete,
                scoreControl: .init(
                    score: 0,
                    maxScore: 0,
                    isMinusEnabled: false,
                    isPlusEnabled: false,
                    isVisible: false
                ),
                bottomControls: .init(
                    isVisible: false,
                    showsGradeButton: false,
                    canGoPrevious: false,
                    canGoNext: false
                )
            )
        }

        if details.questions.indices.contains(selectedQuestionIndex) == false {
            selectedQuestionIndex = 0
        }

        let selectedQuestion = details.questions[selectedQuestionIndex]
        let selectedAnswer = answer(for: selectedQuestion)

        var rows: [QuizParticipantReviewModels.Row] = [
            .header(title: normalizedQuizTitle(from: details.instance?.title)),
            .questionSwitcher(items: makeQuestionSwitcherItems(from: details.questions))
        ]

        let questionText = normalizedQuestionText(selectedQuestion.text)
        rows.append(.questionText(text: questionText))

        switch selectedQuestion.type {
        case .openEnded:
            rows.append(.openAnswer(text: selectedAnswer?.answer ?? ""))
            if let correctAnswerText = openCorrectAnswerText(selectedQuestion.correctAnswer) {
                rows.append(
                    .answerInfo(
                        .init(
                            badge: .correctAnswer,
                            text: correctAnswerText
                        )
                    )
                )
            }

        case .singleChoice, .multiChoice:
            rows.append(contentsOf: makeOptionRows(question: selectedQuestion, answer: selectedAnswer))

        case .none:
            break
        }

        let pendingOpenCount = pendingOpenQuestionsCount()

        return QuizParticipantReviewModels.ViewData(
            rows: rows,
            selectedQuestionIndex: selectedQuestionIndex,
            checkmarkState: pendingOpenCount > 0
                ? .pending(pendingOpenQuestionsCount: pendingOpenCount)
                : .complete,
            scoreControl: makeScoreControlViewData(question: selectedQuestion, answer: selectedAnswer),
            bottomControls: makeBottomControlsViewData(
                question: selectedQuestion,
                answer: selectedAnswer,
                questionsCount: details.questions.count
            )
        )
    }

    private func makeQuestionSwitcherItems(from questions: [Question]) -> [QuizParticipantReviewModels.QuestionSwitcherItemViewData] {
        questions.enumerated().map { index, question in
            let answer = answer(for: question)
            let isSelected = index == selectedQuestionIndex
            let hasFilledBackground = isQuestionReviewed(answer)
            let borderStyle = resolveQuestionSwitcherBorderStyle(
                question: question,
                answer: answer,
                isSelected: isSelected
            )

            return QuizParticipantReviewModels.QuestionSwitcherItemViewData(
                questionNumber: index + 1,
                maxScore: max(0, question.maxScore ?? 0),
                borderStyle: borderStyle,
                hasFilledBackground: hasFilledBackground
            )
        }
    }

    private func resolveQuestionSwitcherBorderStyle(
        question: Question,
        answer: QuizParticipantAnswer?,
        isSelected: Bool
    ) -> QuizParticipantReviewModels.QuestionSwitcherBorderStyle {
        if isSelected {
            return .selected
        }

        switch question.type {
        case .openEnded:
            if openCorrectAnswerText(question.correctAnswer) != nil {
                if answer?.isCorrect == true {
                    return .correct
                }
                if answer?.isCorrect == false {
                    return .incorrect
                }
                return .neutral
            }

            if isQuestionReviewed(answer) {
                return .none
            }
            return .neutral

        case .singleChoice, .multiChoice:
            if answer?.isCorrect == true {
                return .correct
            }
            if answer?.isCorrect == false {
                return .incorrect
            }
            return .neutral

        case .none:
            return .neutral
        }
    }

    private func makeOptionRows(
        question: Question,
        answer: QuizParticipantAnswer?
    ) -> [QuizParticipantReviewModels.Row] {
        guard let options = question.options, options.isEmpty == false else {
            return []
        }

        let selectedIndexes = parseSelectedIndexes(from: answer?.answer)

        switch question.type {
        case .singleChoice:
            let correctIndex = singleCorrectIndex(question.correctAnswer)
            return options.enumerated().map { index, option in
                let isSelected = selectedIndexes.contains(index)
                let isCorrectOption = correctIndex == index
                let visualState = optionVisualState(isSelected: isSelected, isCorrectOption: isCorrectOption)
                let textStyle = optionTextStyle(isSelected: isSelected, isCorrectOption: isCorrectOption)

                return .option(
                    QuizParticipantReviewModels.OptionRowViewData(
                        text: option,
                        kind: .singleChoice,
                        isSelected: isSelected,
                        visualState: visualState,
                        textStyle: textStyle
                    )
                )
            }

        case .multiChoice:
            let correctIndexes = multipleCorrectIndexes(question.correctAnswer)
            return options.enumerated().map { index, option in
                let isSelected = selectedIndexes.contains(index)
                let isCorrectOption = correctIndexes.contains(index)
                let visualState = optionVisualState(isSelected: isSelected, isCorrectOption: isCorrectOption)
                let textStyle = optionTextStyle(isSelected: isSelected, isCorrectOption: isCorrectOption)

                return .option(
                    QuizParticipantReviewModels.OptionRowViewData(
                        text: option,
                        kind: .multipleChoice,
                        isSelected: isSelected,
                        visualState: visualState,
                        textStyle: textStyle
                    )
                )
            }

        case .openEnded, .none:
            return []
        }
    }

    private func optionVisualState(
        isSelected: Bool,
        isCorrectOption: Bool
    ) -> AnswerOptionMarkControl.VisualState {
        guard isSelected else {
            return .neutral
        }

        return isCorrectOption ? .correct : .incorrect
    }

    private func optionTextStyle(
        isSelected: Bool,
        isCorrectOption: Bool
    ) -> QuizParticipantReviewModels.OptionTextStyle {
        if isSelected {
            return isCorrectOption ? .correct : .incorrect
        }

        if isCorrectOption {
            return .correct
        }

        return .neutral
    }

    private func makeScoreControlViewData(
        question: Question,
        answer: QuizParticipantAnswer?
    ) -> QuizParticipantReviewModels.ScoreControlViewData {
        guard question.type == .openEnded else {
            return .init(
                score: 0,
                maxScore: 0,
                isMinusEnabled: false,
                isPlusEnabled: false,
                isVisible: false
            )
        }

        let maxScore = max(0, question.maxScore ?? 0)
        let score = currentScore(for: question, answer: answer)

        return .init(
            score: score,
            maxScore: maxScore,
            isMinusEnabled: score > 0,
            isPlusEnabled: score < maxScore,
            isVisible: true
        )
    }

    private func pendingOpenQuestionsCount() -> Int {
        guard let questions = details?.questions else {
            return 0
        }

        let openQuestions = questions.filter { $0.type == .openEnded }
        guard openQuestions.isEmpty == false else {
            return 0
        }

        return openQuestions.reduce(into: 0) { count, question in
            if isQuestionReviewed(answer(for: question)) == false {
                count += 1
            }
        }
    }

    private func isQuestionReviewed(_ answer: QuizParticipantAnswer?) -> Bool {
        answer?.isReviewed == true
    }

    private func answer(for question: Question) -> QuizParticipantAnswer? {
        let questionId = normalizedString(question.id)
        guard questionId.isEmpty == false else {
            return nil
        }

        return answersByQuestionId[questionId]
    }

    private func selectedOpenQuestionContext() -> (question: Question, answer: QuizParticipantAnswer?, questionId: String)? {
        guard let details else {
            return nil
        }
        guard details.questions.indices.contains(selectedQuestionIndex) else {
            return nil
        }

        let question = details.questions[selectedQuestionIndex]
        guard question.type == .openEnded else {
            return nil
        }

        let questionId = normalizedString(question.id)
        guard questionId.isEmpty == false else {
            return nil
        }

        let answer = answersByQuestionId[questionId]
        return (question, answer, questionId)
    }

    private func currentScore(
        for question: Question,
        answer: QuizParticipantAnswer?
    ) -> Int {
        let maxScore = max(0, question.maxScore ?? 0)
        let questionId = normalizedString(question.id)

        let draftScore = scoreDraftByQuestionId[questionId]
        let resolvedScore = draftScore ?? answer?.score ?? 0
        return min(max(0, resolvedScore), maxScore)
    }

    private func updateAnswerScore(
        questionId: String,
        existingAnswer: QuizParticipantAnswer?,
        score: Int
    ) {
        if let existingAnswer {
            answersByQuestionId[questionId] = QuizParticipantAnswer(
                answer: existingAnswer.answer,
                isCorrect: existingAnswer.isCorrect,
                isReviewed: true,
                questionId: existingAnswer.questionId,
                score: score,
                timeSpentMs: existingAnswer.timeSpentMs
            )
            return
        }

        answersByQuestionId[questionId] = QuizParticipantAnswer(
            answer: nil,
            isCorrect: nil,
            isReviewed: true,
            questionId: questionId,
            score: score,
            timeSpentMs: nil
        )
    }

    private func rebuildAnswersIndex(_ answers: [QuizParticipantAnswer]) {
        var indexed: [String: QuizParticipantAnswer] = [:]
        answers.forEach { answer in
            let questionId = normalizedString(answer.questionId)
            guard questionId.isEmpty == false else {
                return
            }
            indexed[questionId] = answer
        }

        answersByQuestionId = indexed
    }

    private func parseSelectedIndexes(from answerText: String?) -> Set<Int> {
        let normalized = normalizedString(answerText)
        guard normalized.isEmpty == false else {
            return []
        }

        let cleaned = normalized
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")

        let indexes = cleaned
            .split(whereSeparator: { character in
                character == "," || character == ";" || character.isWhitespace
            })
            .compactMap { Int($0) }

        return Set(indexes)
    }

    private func singleCorrectIndex(_ correctAnswer: QuestionCorrectAnswer?) -> Int? {
        guard case let .singleChoice(index) = correctAnswer else {
            return nil
        }
        return index
    }

    private func multipleCorrectIndexes(_ correctAnswer: QuestionCorrectAnswer?) -> Set<Int> {
        guard case let .multipleChoice(indexes) = correctAnswer else {
            return []
        }
        return Set(indexes)
    }

    private func normalizedString(_ string: String?) -> String {
        string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func normalizedQuizTitle(from serviceTitle: String?) -> String {
        let title = normalizedString(serviceTitle)
        if title.isEmpty == false {
            return title
        }

        let initialTitle = normalizedString(initialData.quizTitle)
        return initialTitle.isEmpty ? "Квиз" : initialTitle
    }

    private func normalizedQuestionText(_ text: String?) -> String {
        let normalizedText = normalizedString(text)
        return normalizedText.isEmpty ? "Вопрос без текста" : normalizedText
    }

    private func openCorrectAnswerText(_ correctAnswer: QuestionCorrectAnswer?) -> String? {
        guard case let .openText(text) = correctAnswer else {
            return nil
        }

        let normalizedText = normalizedString(text)
        return normalizedText.isEmpty ? nil : normalizedText
    }

    private func makeBottomControlsViewData(
        question: Question,
        answer: QuizParticipantAnswer?,
        questionsCount: Int
    ) -> QuizParticipantReviewModels.BottomControlsViewData {
        let isOpenQuestion = question.type == .openEnded
        let shouldShowGradeButton: Bool = {
            guard isOpenQuestion else { return false }
            if answer?.isReviewed == false {
                return true
            }
            return hasScoreChanges(question: question, answer: answer)
        }()

        return .init(
            isVisible: questionsCount > 0,
            showsGradeButton: shouldShowGradeButton,
            canGoPrevious: selectedQuestionIndex > 0,
            canGoNext: selectedQuestionIndex < questionsCount - 1
        )
    }

    private func hasScoreChanges(
        question: Question,
        answer: QuizParticipantAnswer?
    ) -> Bool {
        currentScore(for: question, answer: answer) != persistedScore(for: question, answer: answer)
    }

    private func persistedScore(
        for question: Question,
        answer: QuizParticipantAnswer?
    ) -> Int {
        let maxScore = max(0, question.maxScore ?? 0)
        let persisted = answer?.score ?? 0
        return min(max(0, persisted), maxScore)
    }
}

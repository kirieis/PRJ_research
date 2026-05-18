import java.util.List;

public class QuestionDto {
    private String id;
    private String text;
    private List<String> options;      // chỉ dùng cho quiz
    private String correctAnswer;      // chỉ dùng cho quiz
    private String explanation;
    // getters, setters
}

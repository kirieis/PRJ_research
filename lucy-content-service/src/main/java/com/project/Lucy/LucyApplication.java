import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class TestParser implements CommandLineRunner {
    private final DocxParserService parser;

    public TestParser(DocxParserService parser) {
        this.parser = parser;
    }

    @Override
    public void run(String... args) throws Exception {
        String path = "D:/your-folder/LISA_Stage1.docx"; // đường dẫn file thật
        ParsedDocumentDto doc = parser.parseDocument(path, "LISA");
        System.out.println("Language: " + doc.getLanguageCode());
        for (StageContentDto stage : doc.getStages()) {
            System.out.println("Stage " + stage.getStageNumber() + ": " + stage.getStageName());
            for (LevelContentDto level : stage.getLevels()) {
                System.out.println("  Level " + level.getLevelNumber() + ": " + level.getTopicName());
                for (SubLevelContentDto sub : level.getSubLevels()) {
                    System.out.println("    Sub: " + sub.getTitle());
                    System.out.println("      Vocab: " + sub.getVocabulary().size());
                    System.out.println("      AI: " + sub.getAiSupportQuestions().size());
                    System.out.println("      Quiz: " + sub.getQuizQuestions().size());
                }
            }
        }
    }
}

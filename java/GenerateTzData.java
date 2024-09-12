import java.io.File;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.time.zone.ZoneOffsetTransition;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class GenerateTzData {
  private static DateTimeFormatter offsetDateFormatter = DateTimeFormatter.ISO_OFFSET_DATE_TIME;
  private static DateTimeFormatter localDateFormatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
  private static DateTimeFormatter zoneAbbrFormatter = DateTimeFormatter.ofPattern("z");

  private static String buildEntry(String timezone, LocalDateTime localDateTime) {
    ZoneId zoneId = ZoneId.of(timezone);
    ZoneOffsetTransition transition = zoneId.getRules().getTransition(localDateTime);

    StringBuilder sb = new StringBuilder();
    sb.append(timezone);
    sb.append(";");
    sb.append(localDateTime.format(localDateFormatter));
    sb.append(";");

    if (transition == null) {
      sb.append("ok;");
      ZonedDateTime zonedDateTime = localDateTime.atZone(zoneId);
      sb.append(zonedDateTime.format(offsetDateFormatter).replace("Z", "+00:00"));
      sb.append(";");
      sb.append(zonedDateTime.format(zoneAbbrFormatter));
    } else if(transition.isGap()) {
      sb.append("gap;");
      sb.append(transition.getDateTimeBefore().minus(1, ChronoUnit.MICROS).atZone(zoneId).format(offsetDateFormatter).replace("Z", "+00:00"));
      sb.append(";");
      sb.append(transition.getDateTimeBefore().minus(1, ChronoUnit.MICROS).atZone(zoneId).format(zoneAbbrFormatter));
      sb.append(";");
      sb.append(transition.getDateTimeAfter().atZone(zoneId).format(offsetDateFormatter).replace("Z", "+00:00"));
      sb.append(";");
      sb.append(transition.getDateTimeAfter().atZone(zoneId).format(zoneAbbrFormatter));
    } else if(transition.isOverlap()) {
      sb.append("ambiguous;");
      sb.append(localDateTime.atOffset(transition.getOffsetBefore()).format(offsetDateFormatter).replace("Z", "+00:00"));
      sb.append(";");
      sb.append(localDateTime.atOffset(transition.getOffsetBefore()).atZoneSimilarLocal(zoneId).format(zoneAbbrFormatter));
      sb.append(";");
      sb.append(localDateTime.atOffset(transition.getOffsetAfter()).format(offsetDateFormatter).replace("Z", "+00:00"));
      sb.append(";");
      sb.append(localDateTime.atOffset(transition.getOffsetAfter()).atZoneSimilarLocal(zoneId).format(zoneAbbrFormatter));
    } else {
      throw new RuntimeException("Unexpected case");
    }

    ZonedDateTime utcDateTime = localDateTime.atZone(ZoneId.of("Etc/UTC"));
    ZonedDateTime shiftedZonedDateTime = utcDateTime.withZoneSameInstant(ZoneId.of(timezone));
    sb.append(";");
    sb.append(shiftedZonedDateTime.format(offsetDateFormatter).replace("Z", "+00:00"));
    sb.append(";");
    sb.append(shiftedZonedDateTime.format(zoneAbbrFormatter));

    return sb.toString();
  }

  public static void main(String[] args) throws IOException {
    if (args.length < 1) {
            throw new IllegalArgumentException("Missing command line argument: input directory path.");
        }
    String ianaTzVersion = java.time.zone.ZoneRulesProvider
            .getVersions("UTC")
            .lastEntry()
            .getKey();

    System.out.println("IANA tz version: " + ianaTzVersion);

    String basePath = new File("").getAbsolutePath();
    String input = args[0];
    String inputDir = Paths.get(basePath, input).toString();

    String outputDir = Files.createDirectories(Paths.get(basePath, "files/output/", ianaTzVersion, "java")).toString();

    for (File file : new File(outputDir).listFiles()) file.delete();

    Charset utf8 = StandardCharsets.UTF_8;

    File f = new File(inputDir);
    String[] file_paths = f.list();

    for (String filename : file_paths) {
      String file_path = Paths.get(inputDir, filename).toString();
      Stream<String> lines = Files.lines(Paths.get(file_path));

      List<String> content = lines.collect(Collectors.toList());

      lines.close();

      List<String> result = new ArrayList<>();
      result.add(ianaTzVersion);

      for (String line : content) {
        String[] splitData = line.split(";");

        String timezone = splitData[0];
        String date = splitData[1];

        LocalDate localDate = LocalDate.parse(date);
        LocalTime localTime = LocalTime.of(0, 0);

        while (true) {
          LocalDateTime localDateTime = LocalDateTime.of(localDate.getYear(), localDate.getMonth(), localDate.getDayOfMonth(), localTime.getHour(), localTime.getMinute(), localTime.getSecond());

          result.add(buildEntry(timezone, localDateTime));

          if (localTime.getHour() == 23 && localTime.getMinute() == 45) {
            break;
          }
          localTime = localTime.plusMinutes(15);
        }
      }

      Files.write(Paths.get(outputDir, filename), result, utf8);
    }
  }
}

using System;
using System.Diagnostics;
using System.IO;
using System.Collections.Generic;
using System.Text.RegularExpressions;

class Convertidor
{
    static void Main()
    {
        Console.WriteLine("=== Video Converter ===\n");

        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
        string ffmpegPath = Path.Combine(baseDir, "ffmpeg.exe");
        string ffprobePath = Path.Combine(baseDir, "ffprobe.exe");
        string inputDir = Path.Combine(baseDir, "input");
        string outputDir = Path.Combine(baseDir, "output");

        if (!File.Exists(ffmpegPath) || !File.Exists(ffprobePath))
            ExitWithMessage("Error: ffmpeg.exe and/or ffprobe.exe not found in the program folder.");

        Directory.CreateDirectory(inputDir);
        Directory.CreateDirectory(outputDir);
        ClearOutputDirectoryWithPrompt(outputDir);

        string[] extensions = { "*.mp4", "*.mov", "*.avi", "*.mkv", "*.ogv", "*.webm" };
        var filesList = new List<string>();
        foreach (var ext in extensions)
            filesList.AddRange(Directory.GetFiles(inputDir, ext));

        if (filesList.Count == 0)
            ExitWithMessage("Error: No video files found in the 'input' folder.");

        Console.WriteLine("Available output formats:");
        Console.WriteLine("1) OGV (Theora/Vorbis)");
        Console.WriteLine("2) MP4 (H.264/AAC)");
        Console.WriteLine("3) WebM (VP9/Opus)");
        int formatChoiceNum = GetIntInRange("Select a format (1-3): ", 1, 3);
        string formatChoice = formatChoiceNum.ToString();

        Console.WriteLine("\nSelect resolution:");
        Console.WriteLine("=== 16:9 ===");
        Console.WriteLine("1) 3840x2160 (4K)");
        Console.WriteLine("2) 2560x1440 (2K/QHD)");
        Console.WriteLine("3) 1920x1080 (1080p/FHD)");
        Console.WriteLine("4) 1600x900");
        Console.WriteLine("5) 1280x720 (720p/HD)");
        Console.WriteLine("6) 960x540 (qHD)");
        Console.WriteLine("7) 854x480 (FWVGA)");
        Console.WriteLine("8) 640x360 (nHD)");
        Console.WriteLine("9) 426x240 (Ultra Low)");
        Console.WriteLine("\n=== 4:3 ===");
        Console.WriteLine("10) 1600x1200");
        Console.WriteLine("11) 1024x768 (XGA)");
        Console.WriteLine("12) 800x600 (SVGA)");
        Console.WriteLine("13) 640x480 (VGA)");
        Console.WriteLine("14) 320x240 (QVGA)");
        Console.WriteLine("\n=== 1:1 ===");
        Console.WriteLine("15) 1080x1080");
        Console.WriteLine("16) 512x512");
        Console.WriteLine("\n17) Custom (manual entry)");
        Console.WriteLine("18) Keep original");
        int resChoiceNum = GetIntInRange("\nOptions (1-18): ", 1, 18);
        string resChoice = resChoiceNum.ToString();

        string scaleFilter = resChoice switch
        {
            "1" => "scale=3840:2160:force_original_aspect_ratio=decrease",
            "2" => "scale=2560:1440:force_original_aspect_ratio=decrease",
            "3" => "scale=1920:1080:force_original_aspect_ratio=decrease",
            "4" => "scale=1600:900:force_original_aspect_ratio=decrease",
            "5" => "scale=1280:720:force_original_aspect_ratio=decrease",
            "6" => "scale=960:540:force_original_aspect_ratio=decrease",
            "7" => "scale=854:480:force_original_aspect_ratio=decrease",
            "8" => "scale=640:360:force_original_aspect_ratio=decrease",
            "9" => "scale=426:240:force_original_aspect_ratio=decrease",
            "10" => "scale=1600:1200:force_original_aspect_ratio=decrease",
            "11" => "scale=1024:768:force_original_aspect_ratio=decrease",
            "12" => "scale=800:600:force_original_aspect_ratio=decrease",
            "13" => "scale=640:480:force_original_aspect_ratio=decrease",
            "14" => "scale=320:240:force_original_aspect_ratio=decrease",
            "15" => "scale=1080:1080:force_original_aspect_ratio=decrease",
            "16" => "scale=512:512:force_original_aspect_ratio=decrease",
            "17" => GetCustomResolution(),
            _ => ""
        };

        Console.Write("Desired FPS (leave empty to keep original): ");
        string fpsInput;
        while (true)
        {
            fpsInput = Console.ReadLine();
            if (string.IsNullOrWhiteSpace(fpsInput) || int.TryParse(fpsInput, out int fps) && fps > 0)
                break;
            Console.WriteLine("Please enter a positive number or leave blank.");
        }
        string fpsFilter = !string.IsNullOrWhiteSpace(fpsInput) ? $"fps={fpsInput}" : "";

        string filterChain = "";
        if (!string.IsNullOrEmpty(scaleFilter) && !string.IsNullOrEmpty(fpsFilter))
            filterChain = $"{scaleFilter},{fpsFilter}";
        else if (!string.IsNullOrEmpty(scaleFilter))
            filterChain = scaleFilter;
        else if (!string.IsNullOrEmpty(fpsFilter))
            filterChain = fpsFilter;

        bool keepAudio = GetYesNo("Keep audio? (y/n): ") == "y";

        string extensionOut;
        string codecVideo;
        string codecAudio;

        switch (formatChoice)
        {
            case "2":
                extensionOut = ".mp4";
                codecVideo = "-vcodec libx264 -crf 23 -preset medium";
                codecAudio = keepAudio ? "-acodec aac -b:a 128k" : "-an";
                break;
            case "3":
                extensionOut = ".webm";
                codecVideo = "-vcodec libvpx-vp9 -b:v 1M";
                codecAudio = keepAudio ? "-acodec libopus -b:a 96k" : "-an";
                break;
            default:
                extensionOut = ".ogv";
                codecVideo = "-vcodec libtheora -q:v 7";
                codecAudio = keepAudio ? "-acodec libvorbis -q:a 6" : "-an";
                break;
        }

        foreach (var file in filesList)
        {
            string fileName = Path.GetFileNameWithoutExtension(file);
            string outputFileBase = Path.Combine(outputDir, $"{fileName}_converted{extensionOut}");
            string outputFile = outputFileBase;
            int counter = 1;
            while (File.Exists(outputFile))
            {
                outputFile = Path.Combine(outputDir, $"{fileName}_converted_{counter}{extensionOut}");
                counter++;
            }

            double totalSeconds = GetVideoDuration(ffprobePath, file);
            if (totalSeconds <= 0)
            {
                Console.WriteLine($"Skipping {fileName}, could not read duration.");
                continue;
            }

            string filterArg = !string.IsNullOrEmpty(filterChain) ? $"-vf \"{filterChain}\"" : "";
            string arguments = $"-i \"{file}\" {filterArg} {codecVideo} {codecAudio} \"{outputFile}\"";

            Console.WriteLine($"\nConverting: {Path.GetFileName(file)}");
            RunFFmpegWithProgress(ffmpegPath, arguments, totalSeconds);
            Console.WriteLine($"\nSaved to: {outputFile}");
        }

        ExitWithMessage("Process completed.\nConverted videos are in: " + outputDir);
    }

    static int GetIntInRange(string prompt, int min, int max)
    {
        int value;
        while (true)
        {
            Console.Write(prompt);
            string input = Console.ReadLine();
            if (int.TryParse(input, out value) && value >= min && value <= max)
                return value;
            Console.WriteLine($"Please enter a number between {min} and {max}.");
        }
    }

    static int GetPositiveInt(string prompt)
    {
        int value;
        while (true)
        {
            Console.Write(prompt);
            string input = Console.ReadLine();
            if (int.TryParse(input, out value) && value > 0)
                return value;
            Console.WriteLine("Please enter a positive number.");
        }
    }

    static string GetYesNo(string prompt)
    {
        while (true)
        {
            Console.Write(prompt);
            string input = (Console.ReadLine() ?? "").Trim().ToLower();
            if (input == "y" || input == "n")
                return input;
            Console.WriteLine("Please enter 'y' or 'n'.");
        }
    }

    static string GetCustomResolution()
    {
        int width = GetPositiveInt("Enter width: ");
        int height = GetPositiveInt("Enter height: ");
        return $"scale={width}:{height}:force_original_aspect_ratio=decrease";
    }

    static void ClearOutputDirectoryWithPrompt(string outputDir)
    {
        string response = GetYesNo($"Do you want to delete all contents of '{outputDir}'? (y/n): ");
        if (response == "y")
        {
            if (Directory.Exists(outputDir))
            {
                foreach (var file in Directory.GetFiles(outputDir))
                {
                    try { File.Delete(file); } catch (Exception ex) { Console.WriteLine($"Could not delete file {file}: {ex.Message}"); }
                }
                foreach (var dir in Directory.GetDirectories(outputDir))
                {
                    try { Directory.Delete(dir, true); } catch (Exception ex) { Console.WriteLine($"Could not delete folder {dir}: {ex.Message}"); }
                }
                Console.WriteLine("Output folder cleared.");
            }
        }
        else
        {
            Console.WriteLine("Output folder was not cleared.");
        }
    }

    static double GetVideoDuration(string ffprobePath, string filePath)
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = ffprobePath,
                Arguments = $"-v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 \"{filePath}\"",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };
            using var proc = new Process();
            proc.StartInfo = psi;
            proc.Start();
            string result = proc.StandardOutput.ReadToEnd().Trim();
            proc.WaitForExit();
            return double.TryParse(result, out double seconds) ? seconds : 0;
        }
        catch
        {
            return 0;
        }
    }

    static void RunFFmpegWithProgress(string ffmpegPath, string arguments, double totalSeconds)
    {
        var psi = new ProcessStartInfo
        {
            FileName = ffmpegPath,
            Arguments = arguments,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var proc = new Process();
        proc.StartInfo = psi;
        proc.Start();

        var timeRegex = new Regex(@"time=(\d+):(\d+):(\d+\.?\d*)");
        while (!proc.StandardError.EndOfStream)
        {
            string line = proc.StandardError.ReadLine();
            if (line == null) continue;
            var match = timeRegex.Match(line);
            if (match.Success)
            {
                double hours = double.Parse(match.Groups[1].Value);
                double minutes = double.Parse(match.Groups[2].Value);
                double seconds = double.Parse(match.Groups[3].Value);
                double currentSeconds = hours * 3600 + minutes * 60 + seconds;
                int percent = (int)((currentSeconds / totalSeconds) * 100);
                DrawProgressBar(percent, 50);
            }
        }
        proc.WaitForExit();
    }

    static void DrawProgressBar(int percent, int width)
    {
        int filled = (int)((percent / 100.0) * width);
        Console.CursorLeft = 0;
        Console.Write("[");
        Console.Write(new string('█', filled));
        Console.Write(new string('-', width - filled));
        Console.Write($"] {percent}%");
    }

    static void ExitWithMessage(string message)
    {
        Console.WriteLine("\n" + message);
        Console.WriteLine("\nPress any key to exit...");
        Console.ReadKey();
        Environment.Exit(0);
    }
}

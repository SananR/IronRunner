package java_painter;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

public class Main {

    public static void main(String[] args) {
        try {
            File img = new File("./src/java_painter/rocketfire1.png");
            BufferedImage image = ImageIO.read(img);
            int[][] data = convertTo2DUsingGetRGB(image);

            for (int y=0; y<data.length; y++) {
                for (int x=0; x<data[0].length; x++) {
                    if (data[y][x] == 0) continue;
                    System.out.println("add $a0, $t6, " + (x+1));
                    System.out.println("add $a1, $t7, " + (y));
                    System.out.println("li $a2, " + integerToHex(data[y][x]));
                    System.out.println("jal paintPixel");
                    System.out.println("");

                }
            }



        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static int[][] convertTo2DUsingGetRGB(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        int[][] result = new int[height][width];

        for (int row = 0; row < height; row++) {
            for (int col = 0; col < width; col++) {
                result[row][col] = image.getRGB(col, row);
            }
        }

        return result;
    }
    private static String integerToHex(int input) {
        return "0x"+Integer.toHexString(input).toString().substring(2);
    }
}

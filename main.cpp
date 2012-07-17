#include <cstdio>
#include <cstdlib>
#include <string>
#include <iostream>
#include <math.h>
#include <sstream>
#include <fstream>

#define MAXLEN 25

using namespace std;

// uncomment for MS Visual Studio
// #pragma pack(1)
typedef struct {
	char id[2]; 
	int file_size;
	int reserved;
	int offset;
} __attribute ((packed)) header_type;

// uncomment for MS Visual Studio
//#pragma pack(1)
typedef struct {
	int header_size;
	int width;
	int height; 
	unsigned short int color_planes; 
	unsigned short int color_depth; 
	unsigned int compression; 
	int image_size;
	int xresolution;
	int yresolution; 
	int num_colors;
	int num_important_colors;
} __attribute ((packed)) information_type;

int* load_bmp(string filepath, header_type &header, information_type &information);
void save_bmp(string filepath, int *img, header_type &header, information_type &informationh, int threshold);
extern void img_process(int *img, int *edges, int height, int width, int threshold);

int main(int argc, char *argv[])
{
    if(argc != 2){
        cout << "Bitmap argument required. Ex, manip.out cell.bmp" << endl;
        exit(-1);
    }
    
    header_type header;
	information_type information;
    string filepath = argv[1];
    char *fpath;
    
    int *img = load_bmp(filepath, header, information);
	cout << filepath << ": " << information.width << " by " << information.height << endl;

    int *edges = new int [information.height*information.width];
	
	for(int i = 2; i <= 2; i++){
		img_process(img, edges, information.height, information.width, i);
		save_bmp(filepath, edges, header, information, i);
	}
	
	return 0;
}

int* load_bmp(string filepath, header_type &header, information_type &information){

	int *img;
	FILE *fp_bmp;
	ifstream f( filepath.c_str(),ios::binary);
    
	unsigned char data[3];
	int i, j, row_bytes, padding;

	// Read file header
	fread (&header, sizeof(header_type), 1, fp_bmp);
	if (header.id[0] != 'B' || header.id[1] != 'M') {
		fprintf (stderr, "Does not appear to be a .bmp file.  Goodbye.\n");
		exit(-1);
	}
	
	// Read/compute image information
	fread (&information, sizeof(information_type), 1, fp_bmp);	
	row_bytes = information.width * 3;
	padding = row_bytes % 4;
	if (padding)
		padding = 4 - padding;
		
	img = new int[information.height*information.width];

	// Extract image data
	for (i=0; i < information.height; i++) {
		for (j=0; j < information.width; j++) {

			fread (data, sizeof(unsigned char), 3, fp_bmp);
			// use blue
            img[i*information.height+j] = data[0];

		}
		if (padding)
            fread (data, sizeof(unsigned char), padding, fp_bmp);
	}
    fclose(fp_bmp);
	return img;
}

void save_bmp(string filepath, int *img, header_type &header, information_type &information, int threshold){
    ostringstream num;
	num << threshold;
    FILE *fp_bmp;
	
    string output = "edge-" + filepath;
	string temp = "-";
	
	if(threshold < 10)
		temp += "0";
	temp += num.str();

	output.replace(output.find(".bmp"), 7, temp + ".bmp");
	
	string cmd = "cp -f " + filepath + " " + output;
	system(cmd.c_str());

    ofstream f(output.c_str(), ios_base::binary | ios_base::out);
	char *data = new char[3];
	int i, j, row_bytes, padding;
    
    // read file header
    //fwrite (&header, sizeof(header_type), 1, fp_bmp);
	f.write (reinterpret_cast<char*>(&header), sizeof(header_type));
    // read/compute image information
    //fwrite (&information, sizeof(information_type), 1, fp_bmp);
	f.write (reinterpret_cast<char*>(&information), sizeof(information_type));	
    
    row_bytes = information.width * 3;
    padding = row_bytes % 4;
    if (padding)
        padding = 4 - padding;
    
    // insert image data (pixel intensities) into image file
    for (i=0; i < information.height; i++) {
        for (j=0; j < information.width; j++) {
            // [0] is blue
            // [1] is green
            // [2] is red	
			data[0] = (char) img[i*information.height+j];
            data[1] = data[0];
            data[2] = data[0];
			f.write (data, sizeof(char[3]));
        }
        if (padding) {
            data[0] = 0;
            data[1] = 0;
            data[2] = 0;
			f.write (data, sizeof(char[3]));
        }
    }
}
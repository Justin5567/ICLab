#include <iostream>
#include <vector>
#include <random>
#include <fstream>
#include <stdlib.h>
#include <time.h> 
#include <iomanip>
#include <cmath>
using namespace std;
// global variable
vector< vector <int> > img_vec(16,vector<int>(16,0));
vector<vector <int > > input_template(3,vector<int>(3,0));
vector<int> inst_vec(16,0);
int img_size;

// do op0 cross correlation test
void opt0(){
        vector< vector<int > > new_image(16,vector<int>(16,0));
        for(int y=0;y<img_size;y=y+1){
            for(int x=0;x<img_size;x=x+1){
               // cout<<y<<" "<<x<<endl;
                //vector< vector<int> > tmp_mat(3,vector<int>(3,0));
                vector<int > tmp_mat(9,0);
                if(y-1>=0 && x-1>=0){
                    tmp_mat[0]=img_vec[y-1][x-1];
                }
                if(y-1>=0 && x>=0){
                    tmp_mat[1]=img_vec[y-1][x];
                }
                if(y-1>=0 && x+1<img_size){
                    tmp_mat[2]=img_vec[y-1][x+1];
                }
                if(y>=0 && x-1>=0){
                    tmp_mat[3]=img_vec[y][x-1];
                }
                if(y>=0 && x>=0){
                    tmp_mat[4]=img_vec[y][x];
                }
                if(y>=0 && x+1<img_size){
                    tmp_mat[5]=img_vec[y][x+1];
                }
                if(y+1<img_size && x-1>=0){
                    tmp_mat[6]=img_vec[y+1][x-1];
                }
                if(y+1<img_size && x>=0){
                    tmp_mat[7]=img_vec[y+1][x];
                }
                if(y+1<img_size && x+1<img_size){
                    tmp_mat[8]=img_vec[y+1][x+1];
                }
                new_image[y][x] = tmp_mat[0]*input_template[0][0]+
                                  tmp_mat[1]*input_template[0][1]+
                                  tmp_mat[2]*input_template[0][2]+
                                  tmp_mat[3]*input_template[1][0]+
                                  tmp_mat[4]*input_template[1][1]+
                                  tmp_mat[5]*input_template[1][2]+
                                  tmp_mat[6]*input_template[2][0]+
                                  tmp_mat[7]*input_template[2][1]+
                                  tmp_mat[8]*input_template[2][2];
            }
        }
        img_vec = new_image;
}
// do op1  max pooling test
void opt1(){
    if(img_size==4){
        
    }
    else{
        //vector < vector < int> > new_image(img_size/2,vector<int>(img_size/2,0));
        vector < vector < int> > new_image(16,vector<int>(16,0));
        for(int y=0;y<img_size;y=y+2){
            for(int x=0;x<img_size;x=x+2){
                //cout<<y<<" "<<x<<endl;
                int mx=x;
                int my=y;
                if(img_vec[y][x+1]>img_vec[my][mx]){
                    mx = x+1;
                    my = y;
                }
                if(img_vec[y+1][x]>img_vec[my][mx]){
                    mx = x;
                    my = y+1;
                } 
                if(img_vec[y+1][x+1]>img_vec[my][mx]){
                    mx = x+1;
                    my = y+1;
                }
                new_image[y/2][x/2]=img_vec[my][mx];
            }
        }
        img_size /=2;
        img_vec = new_image;
    }
}
// do op2 horizontal flip test
void opt2(){
        vector< vector<int > > new_image(16,vector<int>(16,0));
        for(int x=0;x<img_size/2;x=x+1){
            for(int y=0;y<img_size;y=y+1){
                new_image[y][x] = img_vec[y][img_size-x-1];
                new_image[y][img_size-x-1]=img_vec[y][x];
            }
        }
        img_vec = new_image;
}
// do op3 vertical flip test
void opt3(){
    vector< vector<int > > new_image(16,vector<int>(16,0));
    for(int y=0;y<img_size/2;y=y+1){
        for(int x=0;x<img_size;x=x+1){
            new_image[y][x] = img_vec[img_size-y-1][x];
            new_image[img_size-y-1][x]=img_vec[y][x];
        }
    }
    img_vec = new_image;
}
// do op4 left diagnal test   
void opt4(){
    vector< vector<int > > new_image(16,vector<int>(16,0));
    for(int x=0;x<img_size;x++){
        for(int y=0;y<img_size;y++){
            new_image[img_size-1-x][img_size-1-y] = img_vec[y][x];
        }
    }
    img_vec = new_image;
}        
// do opt5 right diagnal test
void opt5(){
    vector< vector<int > > new_image(16,vector<int>(16,0));
    for(int x=0;x<img_size;x++){
        for(int y=0;y<img_size;y++){
            new_image[x][y] = img_vec[y][x];
        }
    }
    img_vec = new_image;
}   
// do opt6 zoom in test
void opt6(){
    if(img_size==16){

    }
    else{
        vector< vector<int > > new_image(16,vector<int>(16,0));
        for(int y=0;y<img_size;y++){
            for(int x=0;x<img_size;x++){
                new_image[y*2][x*2] = img_vec[y][x];
                new_image[y*2][x*2+1] = img_vec[y][x]/3;
                new_image[y*2+1][x*2] = (img_vec[y][x]*2)/3+20;
                float tmp_floor= img_vec[y][x];
                float tmp_floor2 = tmp_floor/2;
                new_image[y*2+1][x*2+1] = floor(tmp_floor2);
            }
        }
        img_size*=2;
        img_vec = new_image;
    }
        
}   
// do opt6 short cut test
void opt7(){ 
    if(img_size==4){

    }
    else{
        vector< vector<int > > new_image(16,vector<int>(16,0));
        int curr_y = 0;
        int curr_x = 0;
        for(int y=img_size/4;y<img_size*3/4;y++){
            for(int x=img_size/4;x<img_size*3/4;x++){
                // cout<<y<<" "<<x<<endl;
                // cout<<curr_y<<" "<<curr_x<<endl;;
                float tmp_floor = img_vec[y][x];
                float tmp_floor2 = floor(tmp_floor/2);
                new_image[curr_y][curr_x] = tmp_floor2+50;
                curr_x++;
            }
            curr_x=0;
            curr_y++;
        }
        img_size/=2;
        img_vec = new_image;
    }
        
}   

int main(){
    ofstream OutFile_input("input_t16.txt");
    ofstream OutFile_output("output_t16.txt");
    srand(time(NULL));
    int patcount = 500;
    //int range_max = 32767;
    int range_max = 63;
    //int range_min = -32768;
    int range_min = -64;
    for(int pat=0;pat<patcount;pat++){
        // --------------------------------------
        // initialize
        for(int i=0;i<16;i++){
            inst_vec[i] = 0;
        }
        for(int a=0;a<16;a++){
            for(int b=0;b<16;b++){
                img_vec[a][b] = 0;
            }
        }
        for(int a=0;a<3;a++){
            for(int b=0;b<3;b++){
                input_template[a][b]=0;
            }
        }
        img_size = rand()%3;
        if(img_size==0)
            img_size = 4;
        else if(img_size==1)
            img_size = 8;
        else 
            img_size = 16;
        // --------------------------------------
        for(int i=0;i<img_size;i=i+1){
            for(int j=0;j<img_size;j=j+1){
                int tmp_img_val = rand() % (range_max-range_min+1)+range_min;
                img_vec[i][j] = tmp_img_val;
            }
        }
        
        for(int i=0;i<3;i=i+1){
            for(int j=0;j<3;j=j+1){
                int tmp_templage_val = rand() % (range_max-range_min+1)+range_min;
                input_template[i][j] = tmp_templage_val;
            }
        }
        //int inst_num = rand()%(16-1+1)+1;
        int inst_num = 16;
        cout<<inst_num<<endl;
        //inst_vec[0]=7;
        
        for(int i=0;i<inst_num-1;i++){
            int tmp_opt = rand() %(7-1+1)+1;
            //int tmp_opt=0;
            inst_vec[i]=(tmp_opt);
        }
        
        /*
        for(int i=0;i<inst_num;i++){
            cout<<inst_vec[i]<<" ";
        }
        cout<<endl;
        */
        cout<<"CURR IMGAE"<<endl;
        for(int i=0;i<img_size;i=i+1){
            for(int j=0;j<img_size;j=j+1){
                cout<<setw(3)<<img_vec[i][j]<<" ";
            }
            cout<<endl;
        }
        cout<<"CURR TEMPLATE"<<endl;
        for(int i=0;i<3;i=i+1){
            for(int j=0;j<3;j=j+1){
                cout<<setw(3)<<input_template[i][j]<<" ";
            }
            cout<<endl;
        }
        OutFile_input<<img_size<<endl<<endl;
        for(int i=0;i<3;i++){
            for(int j=0;j<3;j++){
                OutFile_input<<setw(3)<<input_template[i][j]<<" ";
            }
            OutFile_input<<endl;
        }
        OutFile_input<<endl;
        for(int i=0;i<inst_num;i++){
            OutFile_input<<inst_vec[i]<<" ";
        }
        OutFile_input<<endl<<endl;
        for(int y=0;y<img_size;y++){
            for(int x=0;x<img_size;x++){
                OutFile_input<<setw(3)<<img_vec[y][x]<<" ";
            }
            OutFile_input<<endl;
        }
        OutFile_input<<endl;

        //cout<<"start OP\n";
        int curr_count = 0;
        while(inst_vec[curr_count]!=0){
            cout<<"curr inst"<<inst_vec[curr_count]<<endl;
            //cout<<"curr img_size"<<img_size<<endl;

           switch(inst_vec[curr_count]) { 
            case 0:
                cout<<"error"<<endl;
                exit(1);
                break;
            case 1:
                opt1();
                break;
            case 2:
                opt2();
                break;
            case 3:
                opt3();
                break;
            case 4:
                opt4();
                break;
            case 5:
                opt5();
                break;
            case 6:
                opt6();
                break;
            case 7:
                opt7();
                break;
            
            default: 
                cout<<"THERE is something WRONG\n";
                exit(1);
                break;
            } 
            
            curr_count++;
        }
        
        cout<<"curr inst 0"<<endl;
        //cout<<"curr image size"<<img_size<<endl;
        opt0();
        
       OutFile_output<<img_size<<endl;
       int max_x=0;
       int max_y=0;
       int val = -99999;
       for(int y=0;y<img_size;y++){
           for(int x=0;x<img_size;x++){
               if(img_vec[y][x]>val){
                   val = img_vec[y][x];
                   max_x = x;
                   max_y = y;
               }
           }
       }
       OutFile_output<<max_x<<" "<<max_y<<endl;
       vector<int > pos_vec;
       for(int i=0;i<9;i++){
           if(i==0 && max_x!=0 && max_y!=0){
                pos_vec.emplace_back((max_y-1)*img_size+(max_x-1));
                //OutFile_output<<(max_y-1)*img_size+(max_x-1)<<" ";   
           }
           if(i==1 && max_y!=0){
               pos_vec.emplace_back((max_y-1)*img_size+(max_x));
                // OutFile_output<<(max_y-1)*img_size+(max_x)<<" ";   
           }
           if(i==2 && max_x+1!=img_size && max_y!=0){
               pos_vec.emplace_back((max_y-1)*img_size+(max_x+1));
                // OutFile_output<<(max_y-1)*img_size+(max_x+1)<<" ";  
           }
           if(i==3 && max_x!=0 ){
               pos_vec.emplace_back((max_y)*img_size+(max_x-1));
                // OutFile_output<<(max_y)*img_size+(max_x-1)<<" ";    
           }
           if(i==4 ){
               pos_vec.emplace_back((max_y)*img_size+(max_x));
                // OutFile_output<<(max_y)*img_size+(max_x)<<" ";     
           }
           if(i==5 && max_x+1!=img_size){
               pos_vec.emplace_back((max_y)*img_size+(max_x+1));
                // OutFile_output<<(max_y)*img_size+(max_x+1)<<" ";     
           }
           if(i==6 && max_x!=0 && max_y+1!=img_size){
               pos_vec.emplace_back((max_y+1)*img_size+(max_x-1));
                // OutFile_output<<(max_y+1)*img_size+(max_x-1)<<" ";     
           }
           if(i==7  && max_y+1!=img_size){
               pos_vec.emplace_back((max_y+1)*img_size+(max_x));
                // OutFile_output<<(max_y+1)*img_size+(max_x)<<" ";     
           }
           if(i==8 && max_x+1!=img_size && max_y+1!=img_size){
               pos_vec.emplace_back((max_y+1)*img_size+(max_x+1));
                // OutFile_output<<(max_y+1)*img_size+(max_x+1)<<" ";     
           }
       }
       OutFile_output<<pos_vec.size()<<endl;
       for(int i=0;i<pos_vec.size();i++){
           OutFile_output<<pos_vec[i]<<" ";
       }

       OutFile_output<<endl;
        for(int y1=0;y1<img_size;y1++){
            for(int x1=0;x1<img_size;x1++){
                OutFile_output<<setw(5)<<img_vec[y1][x1]<<" ";
            }
            OutFile_output<<endl;
        }
        OutFile_output<<endl;



        cout<<"PRINT NEW IMGAE"<<endl;
        for(int y1=0;y1<img_size;y1++){
            for(int x1=0;x1<img_size;x1++){
                cout<<setw(5)<<img_vec[y1][x1]<<" ";
            }
            cout<<endl;
        }


        

        







    
        
    

    }
    
    return 0;
}

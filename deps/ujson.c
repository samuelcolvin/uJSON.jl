#include "ujdecode.h"
#include <stdio.h>
#include <wchar.h>
#include <stdlib.h>
#include <string.h>

void process_object(int level, 
                    void *state, 
                    UJObject obj, 
                    wchar_t *key,
                    int key_len,
                    void(*startnew)(void *uobj, wchar_t *key, int *key_length, int *is_dict),
  				    void(*exit)(void *uobj),
 				    void(*add_null_bool_int_c)(void *uobj, wchar_t *key, int *key_length, long long *value, int *value_type),
 					void(*add_double)(void *uobj, wchar_t *key, int *key_length, double *value),
 					void(*add_string)(void *uobj, wchar_t *key, int *key_length, const wchar_t *value, int *value_length),
                    void *uobj
                   )
{
	int value_type = 0;
	long long value = 0;
    switch (UJGetType(obj))
    {
        case UJT_Null:
            {
            	value_type = -1;
            	add_null_bool_int_c(uobj, key, &key_len, &value, &value_type);
                break;
            }
        case UJT_False:
            {
            	value_type = 0;
            	value = 0;
            	add_null_bool_int_c(uobj, key, &key_len, &value, &value_type);
                break;
            }
        case UJT_True:
            {
            	value_type = 0;
            	value = 1;
            	add_null_bool_int_c(uobj, key, &key_len, &value, &value_type);
                break;
            }
        case UJT_Long:
            {
            	value_type = 1;
                value = UJNumericLongLong(obj);
                add_null_bool_int_c(uobj, key, &key_len, &value, &value_type);
                break;
            }
        case UJT_LongLong:
            {
            	value_type = 1;
                value = UJNumericLongLong(obj);
                add_null_bool_int_c(uobj, key, &key_len, &value, &value_type);
                break;
            }
        case UJT_Double:
            {
                double valued = UJNumericFloat(obj);
                add_double(uobj, key, &key_len, &valued);
                break;
            }
        case UJT_String:
            {
                size_t len;
                const wchar_t *value_str = UJReadString(obj, &len);
                int value_length = (int)len;
                add_string(uobj, key, &key_len, value_str, &value_length);
                break;
            }
        case UJT_Array:
            {
            	int is_dict = 0;
            	startnew(uobj, key, &key_len, &is_dict);
                void *iter = NULL;
                UJObject objiter = NULL;
                iter = UJBeginArray(obj);
                wchar_t *empty_key = L"";
                int empty_key_len = 0;
                while(UJIterArray(&iter, &objiter))
                {
                    process_object(level + 1,
                    			   state,
                    			   objiter,
                    			   empty_key,
                    			   empty_key_len,
                    			   startnew,
                    			   exit,
                    			   add_null_bool_int_c,
                    			   add_double,
                    			   add_string,
                    			   uobj);
                }
                exit(uobj);
                break;
            }
        case UJT_Object:
            {
            	int is_dict = 1;
            	startnew(uobj, key, &key_len, &is_dict);
                void *iter = NULL;
                UJObject objiter = NULL;
                UJString key;
                iter = UJBeginObject(obj);
                while(UJIterObject(&iter, &key, &objiter))
                {
//                    printf("key: '%ls'\n", key.ptr);
                    int key_len = (int)key.cchLen;
//                    print_keys(key.ptr, &key_len);
                    process_object(level + 1,
                    			   state,
                    			   objiter,
                    			   key.ptr,
                    			   key_len,
                    			   startnew,
                    			   exit,
                    			   add_null_bool_int_c,
                    			   add_double,
                    			   add_string,
                    			   uobj);
                }
                exit(uobj);
                break;
            }
    }
}

int process_file(char *filename,
				 void(*startnew)(void *uobj, wchar_t *key, int *key_length, int *is_dict),
				 void(*exit)(void *uobj),
				 void(*add_null_bool_int_c)(void *uobj, wchar_t *key, int *key_length, long long *value, int *value_type),
				 void(*add_double)(void *uobj, wchar_t *key, int *key_length, double *value),
				 void(*add_string)(void *uobj, wchar_t *key, int *key_length, const wchar_t *value, int *value_length),
                 void *uobj)
{
    const char *input;
    size_t cbInput;
    void *state;
    FILE *file;
    char buffer[32768];

    UJHeapFuncs hf;
    hf.cbInitialHeap = sizeof(buffer);
    hf.initalHeap = buffer;
    hf.free = free;
    hf.malloc = malloc;
    hf.realloc = realloc;

    file = fopen(filename, "rb");
    if(file==NULL) {
        printf("file not found!\n");
        return 0;
    }
    input = (char *) malloc(1024 * 1024 * 1024);
    cbInput = fread ( (void *) input, 1, 1024 * 1024 * 1024, file);
    fclose(file);
    
    UJObject obj;

    obj = UJDecode(input, cbInput, &hf, &state);
    wchar_t *empty_key = L"";
    int empty_key_len = 0;
    process_object(0,
    			   state,
    			   obj,
    			   empty_key,
    			   empty_key_len,
    			   startnew,
    			   exit,
    			   add_null_bool_int_c,
    			   add_double,
    			   add_string,
    			   uobj);
    UJFree(state);
    return 1;
}
        

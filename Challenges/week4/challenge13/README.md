# How to do CUDA Setup on Google Colab?
- https://colab.research.google.com/

## Steps

1. **Create a New Notebook**  
   - Click **File** > **New notebook**

2. **Enable GPU Hardware Accelerator**  
   - In the top menu, click **Runtime**  
   - Select **Change runtime type**  
   - Under **Hardware accelerator**, choose **GPU (T4 GPU)**  
   - Click **Save**

3. **Verify Python and CUDA Versions**  
   Paste the following into the first code cell and run:
   ```bash
   !python --version
   !nvcc --version
   !pip install nvcc4jupyter
   %load_ext nvcc4jupyter
   ```

Always start the code with
```bash
%%cuda
```


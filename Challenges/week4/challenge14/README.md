## Benchmarking SAXPY on a GPU

**Vary the problem size**  
   We test lengths \(N = 2^{15}\) up to \(2^{25}\) to see how performance changes as the data grows.

**Launch the SAXPY kernel**  
   - Run one thread per element, in blocks of 256 threads.  
   - Each thread does `y[i] = a*x[i] + y[i]`.

6. **Why it matters**  
   - For small \(N\), setup and data transfer take the lion’s share of the time.  
   - As \(N\) grows, you see linear scaling in total time while the pure compute time stays almost flat.  
   - This tells you where the “break-even” point is for when GPU work really pays off. 
For Fibinacci:

![{EACBB75C-3138-433E-8445-2A22EA887081}](https://github.com/user-attachments/assets/01c8e55a-87c9-4f57-bcb8-76eb463661ed)

![{731270E7-8D0E-4EBD-A1BC-BC0E38FBF9C3}](https://github.com/user-attachments/assets/85eddfe2-94cf-48f6-969f-d5238339be4e)


![{8DB2DB77-C699-4867-98AD-FD16490B67A7}](https://github.com/user-attachments/assets/f574299c-b62f-4d91-8948-21ea47837ac9)

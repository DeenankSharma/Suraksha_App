import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/components/navigation_drawer.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _descriptionController = TextEditingController();
  final primaryBlue = const Color.fromARGB(255, 0, 56, 147);

  @override
  Widget build(BuildContext context) {
    HomeBloc homeBloc = HomeBloc();

    return BlocConsumer(
        bloc: homeBloc,
        listener: (context, state) {},
        builder: (context, state) {
          return _buildScaffold(context, state, homeBloc);
          // } else {
          return Container(
            color: Colors.pink,
          );
          // }
        });
  }

  Widget _buildScaffold(
      BuildContext context, dynamic state, HomeBloc homeBloc) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor:
              const Color.fromARGB(255, 0, 56, 147).withOpacity(0.9),
          elevation: 0,
          flexibleSpace: Container(),
          title: Text(
            'Suraksha',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: MediaQuery.of(context).size.height * 0.03,
                  letterSpacing: 1.2,
                ),
          ),
          centerTitle: false,
        ),
      ),
      drawer: const Navigation_Drawer(
        select: 1,
      ),
      body: SingleChildScrollView(
        child: Container(
          height: screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromARGB(255, 106, 206, 245),
                const Color.fromARGB(255, 0, 56, 147).withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenHeight * 0.04),
                  _buildHelpButton(context, state, homeBloc, screenHeight),
                  SizedBox(height: screenHeight * 0.04),
                  _buildOrDivider(),
                  SizedBox(height: screenHeight * 0.04),
                  _buildDetailsForm(context, screenHeight),
                  SizedBox(height: screenHeight * 0.04),
                  _buildSubmitButton(context, state, homeBloc, screenHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildHelpButton(BuildContext context, dynamic state,
      HomeBloc homeBloc, double screenHeight) {
    return BlocBuilder(
        bloc: homeBloc,
        builder: (context, state) {
          bool isHelpRequested = state is HelpRequestedState;

          return Container(
            height: screenHeight * 0.15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color.fromARGB(255, 0, 110, 255).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: const Color.fromARGB(255, 0, 56, 147).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (!isHelpRequested) {
                    context.read<HomeBloc>().add(HelpButtonClickedEvent());
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isHelpRequested
                            ? 'Emergency help already requested'
                            : 'Emergency help requested',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: const Color(0xFF6ACEF5),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    'HELP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenHeight * 0.04,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }

  Widget _buildDetailsForm(BuildContext context, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: screenHeight * 0.02),
        _buildTextField(
          controller: _areaController,
          labelText: 'Area/Street',
          hintText: 'Enter your area or street name',
          prefixIcon: Icons.location_on,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your area';
            }
            return null;
          },
        ),
        SizedBox(height: screenHeight * 0.02),
        _buildTextField(
          controller: _landmarkController,
          labelText: 'Landmark',
          hintText: 'Enter nearby landmark',
          prefixIcon: Icons.place,
        ),
        SizedBox(height: screenHeight * 0.02),
        _buildTextField(
          controller: _descriptionController,
          labelText: 'Description',
          hintText: 'Describe your emergency or situation',
          prefixIcon: Icons.description,
          maxLines: 4,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please provide a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(color: primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryBlue.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryBlue),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(prefixIcon, color: primaryBlue),
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton(BuildContext context, dynamic state,
      HomeBloc homeBloc, double screenHeight) {
    return BlocBuilder(
        bloc: homeBloc,
        builder: (context, state) {
          bool isDescriptionHelpRequested =
              state is HelpRequestedState && state.type == "desc";

          return ElevatedButton(
            onPressed: () {
              if (isDescriptionHelpRequested) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Request Already Submitted',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: Color.fromARGB(255, 0, 204, 255),
                  ),
                );
              } else if (_formKey.currentState!.validate()) {
                context.read<HomeBloc>().add(HelpFormSubmittedEvent(
                    area: _areaController.text,
                    landmark: _landmarkController.text,
                    description: _descriptionController.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Submitting your request...',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: Color.fromARGB(255, 0, 204, 255),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color.fromARGB(255, 0, 56, 147).withOpacity(0.8),
              shadowColor: const Color(0xFF6ACEF5),
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        });
  }
}
